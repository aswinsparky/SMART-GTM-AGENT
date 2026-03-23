from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import os
import asyncio
from dotenv import load_dotenv
import logging
from openai import AsyncOpenAI
from sqlalchemy.orm import Session
import models, schemas, crud
from database import SessionLocal, engine, Base
import json
import boto3

load_dotenv()

# setup basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# create DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Smart GTM Agent API")

# CORS for local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _invoke_bedrock_sync(prompt: str, model_id: str, region: str) -> str:
    """Call Bedrock Claude with the prompt; returns assistant text. Runs in thread."""
    client = boto3.client("bedrock-runtime", region_name=region)
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "temperature": 0.7,
        "system": "You are an expert go-to-market strategist. Keep responses concise and focused. Return only valid JSON.",
        "messages": [{"role": "user", "content": prompt}],
    })
    resp = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=body,
    )
    out = json.loads(resp["body"].read())
    # Messages API response: content is list of blocks; text in block with type "text"
    content = out.get("content", [])
    for block in content:
        if block.get("type") == "text":
            return block.get("text", "")
    return ""

# dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class APIKeyIn(BaseModel):
    api_key: str

@app.get('/api-key')
def get_api_key():
    key = os.getenv('OPENAI_API_KEY')
    return {"present": bool(key), "masked": (key[:4] + '...' + key[-4:]) if key else None}

@app.post('/api-key')
def set_api_key(payload: APIKeyIn):
    api_key = payload.api_key
        
    # Write to .env (note: for local dev only; in production use secure secrets manager)
    env_path = os.path.join(os.getcwd(), '.env')
    updated = False
    
    try:
        if os.path.exists(env_path):
            with open(env_path, 'r') as f:
                lines = f.readlines()
            with open(env_path, 'w') as f:
                for line in lines:
                    if line.startswith('OPENAI_API_KEY='):
                        f.write(f"OPENAI_API_KEY={api_key}\n")
                        updated = True
                    else:
                        f.write(line)
                if not updated:
                    f.write(f"OPENAI_API_KEY={api_key}\n")
        else:
            with open(env_path, 'w') as f:
                f.write(f"OPENAI_API_KEY={api_key}\n")
                
        os.environ['OPENAI_API_KEY'] = api_key

        return {"status": "success", "message": "API key updated successfully"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update API key: {str(e)}")
    
    # already returned above on success; no Flask jsonify here
    return {"status": "success"}

@app.post('/generate-plan')
async def generate_plan(input_data: schemas.GTMInput, db: Session = Depends(get_db)):
    try:
        # read API key and mock-mode flag
        api_key = os.getenv('OPENAI_API_KEY')
        mock_mode = str(os.getenv('MOCK_MODE', '')).lower() in ('1', 'true', 'yes')

        # If mock mode enabled, return a dynamic mock strategy without calling OpenAI (e.g. when over quota)
        if mock_mode:
            logger.info('MOCK_MODE enabled: returning dynamic mock strategy without calling OpenAI')
            
            # Parse competitors into a list
            competitor_list = [c.strip() for c in input_data.competitors.split(',')] if input_data.competitors else []
            
            # Generate dynamic marketing channels based on budget
            budget_value = float(''.join(filter(str.isdigit, input_data.budget))) if any(c.isdigit() for c in input_data.budget) else 5000
            channels = []
            if budget_value >= 10000:
                channels = [
                    {
                        "channel": "Paid Social Media",
                        "strategy": f"Target {input_data.target_audience} through Meta and LinkedIn Ads",
                        "budget_allocation": "40% of budget",
                        "expected_impact": "3x ROAS"
                    },
                    {
                        "channel": "Content Marketing",
                        "strategy": "Thought leadership content focused on industry trends",
                        "budget_allocation": "30% of budget",
                        "expected_impact": "Organic traffic growth"
                    },
                    {
                        "channel": "Industry Events",
                        "strategy": "Sponsor and present at major conferences",
                        "budget_allocation": "30% of budget",
                        "expected_impact": "Direct B2B leads"
                    }
                ]
            else:
                channels = [
                    {
                        "channel": "Social Media Marketing",
                        "strategy": f"Organic content targeting {input_data.target_audience}",
                        "budget_allocation": "50% of budget",
                        "expected_impact": "Brand awareness"
                    },
                    {
                        "channel": "Email Marketing",
                        "strategy": "Nurture campaigns for lead conversion",
                        "budget_allocation": "50% of budget",
                        "expected_impact": "Direct conversions"
                    }
                ]

            strategy = {
                "target_segment": {
                    "primary_audience": input_data.target_audience,
                    "demographics": f"Primary market: {input_data.region}",
                    "psychographics": f"Businesses and individuals interested in {input_data.product_name}",
                    "pain_points": "Need for efficient and cost-effective solutions"
                },
                "marketing_channels": channels,
                "pricing_strategy": {
                    "model": "Value-based pricing" if budget_value >= 10000 else "Competitive pricing",
                    "rationale": f"Aligned with {input_data.target_audience} purchasing power",
                    "competitive_positioning": "Premium quality at competitive rates",
                    "target_margins": "30-40% gross margin"
                },
                "competitor_insights": {
                    "main_competitors": competitor_list if competitor_list else ["No direct competitors identified"],
                    "competitive_advantages": [
                        f"Specialized focus on {input_data.target_audience}",
                        f"Strong presence in {input_data.region}",
                        "Innovative product features"
                    ],
                    "market_gaps": f"Underserved {input_data.target_audience} segment in {input_data.region}",
                    "defense_strategy": "Focus on product differentiation and customer service"
                },
                "predicted_roi": {
                    "expected_return": f"{2.5 if budget_value >= 10000 else 1.8}x",
                    "timeline": "6-12 months",
                    "key_metrics": [
                        "Customer Acquisition Cost (CAC)",
                        "Customer Lifetime Value (CLV)",
                        "Market Share Growth",
                        "Brand Recognition"
                    ],
                    "risk_factors": [
                        "Market competition intensity",
                        "Economic fluctuations",
                        "Changing customer preferences"
                    ]
                }
            }
            predicted_roi = 1.5
            try:
                db_plan = crud.create_plan(db, input_data, strategy, predicted_roi)
            except Exception as e:
                logger.exception('Failed to store mock plan')
                raise HTTPException(status_code=500, detail=f"Failed to store mock plan: {str(e)}")

            return {
                "success": True,
                "data": {
                    "strategy": strategy,
                    "db_id": db_plan.id
                },
                "mock": True
            }

        llm_provider = (os.getenv("LLM_PROVIDER") or "openai").strip().lower()
        bedrock_model = (os.getenv("BEDROCK_MODEL_ID") or "anthropic.claude-3-haiku-20240307-v1:0").strip()
        aws_region = (os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION") or "us-east-1").strip()

        if llm_provider == "bedrock":
            # Bedrock: no API key needed; ECS task role is used
            pass
        elif not api_key:
            raise HTTPException(status_code=401, detail="OpenAI API key not set on server. Please set it via Settings or add to .env or enable MOCK_MODE for dev")

        # build a detailed prompt
        prompt = f"""Generate a detailed go-to-market strategy in JSON format for the following input:
Product: {input_data.product_name}
Target Audience: {input_data.target_audience}
Budget: {input_data.budget}
Region: {input_data.region}
Competitors: {input_data.competitors}

Return a detailed JSON with the following structure:
{{
    "target_segment": {{
        "primary_audience": "Detailed description of core target audience",
        "demographics": "Age, income, location, interests",
        "psychographics": "Values, lifestyle, behaviors",
        "pain_points": "Key challenges and needs"
    }},
    "marketing_channels": [
        {{
            "channel": "Name of channel",
            "strategy": "Detailed strategy for this channel",
            "budget_allocation": "Percentage or amount",
            "expected_impact": "Expected outcomes"
        }}
    ],
    "pricing_strategy": {{
        "model": "Primary pricing model",
        "rationale": "Explanation of pricing strategy",
        "competitive_positioning": "How pricing compares to competitors",
        "target_margins": "Expected margins"
    }},
    "competitor_insights": {{
        "main_competitors": ["List of competitors"],
        "competitive_advantages": ["Our key advantages"],
        "market_gaps": "Identified opportunities",
        "defense_strategy": "How to defend against competition"
    }},
    "predicted_roi": {{
        "expected_return": "Numerical ROI prediction",
        "timeline": "Time to achieve ROI",
        "key_metrics": ["List of KPIs to track"],
        "risk_factors": ["Potential risks to consider"]
    }}
}}

Provide comprehensive details for each section while maintaining valid JSON format."""

        if llm_provider == "bedrock":
            try:
                text = await asyncio.to_thread(
                    _invoke_bedrock_sync, prompt, bedrock_model, aws_region
                )
                if not text:
                    raise ValueError("Bedrock returned empty response")
            except Exception as e:
                msg = str(e)
                logger.exception("Bedrock request failed")
                if "throttl" in msg.lower() or "rate" in msg.lower():
                    raise HTTPException(
                        status_code=429,
                        detail="Bedrock rate limit. Try again shortly or use a different model."
                    )
                raise HTTPException(
                    status_code=500,
                    detail=f"Bedrock failed: {msg}. Ensure the ECS task role has bedrock:InvokeModel and the model is enabled in Bedrock."
                )
        else:
            client = AsyncOpenAI(api_key=api_key)
            try:
                resp = await client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are an expert go-to-market strategist. Keep responses concise and focused."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.7,
                    max_tokens=500,
                    timeout=60.0,
                )
            except Exception as e:
                msg = str(e)
                logger.exception("OpenAI request failed")
                if '429' in msg or 'insufficient_quota' in msg.lower():
                    raise HTTPException(
                        status_code=429,
                        detail="OpenAI quota exceeded. Check your plan and billing at platform.openai.com, or add MOCK_MODE=1 to backend/.env to use mock plans without the API."
                    )
                if 'timeout' in msg.lower() or isinstance(e, TimeoutError):
                    raise HTTPException(
                        status_code=504,
                        detail="Request timed out. The server is experiencing high load, please try again."
                    )
                if 'readtimeout' in msg.lower() or 'read timeout' in msg.lower():
                    raise HTTPException(status_code=504, detail="Request timed out communicating with OpenAI.")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to generate plan: {msg}. Please try again."
                )

            # Extract assistant text (openai>=1.0 returns object with .choices[0].message.content)
            text = None
            try:
                choices = getattr(resp, 'choices', None)
                if choices:
                    first = choices[0]
                    msg = getattr(first, 'message', None)
                    if msg:
                        text = getattr(msg, 'content', None)
                if text is None:
                    text = str(resp)
            except Exception:
                text = str(resp)

        # Clean and parse the response
        try:
            # Remove any markdown code blocks and find JSON
            text = text.replace('```json', '').replace('```', '')
            start = text.find('{')
            end = text.rfind('}')
            
            if start == -1 or end == -1:
                raise ValueError("No JSON object found in response")
                
            json_text = text[start:end+1]
            strategy = json.loads(json_text)
            
            # Validate required fields
            required_fields = ['target_segment', 'marketing_channels', 'pricing_strategy', 
                             'competitor_insights', 'predicted_roi']
            missing_fields = [field for field in required_fields if field not in strategy]
            
            if missing_fields:
                raise ValueError(f"Missing required fields: {', '.join(missing_fields)}")
                
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=500,
                detail="Failed to parse the generated plan. Please try again."
            )
        except ValueError as e:
            raise HTTPException(
                status_code=500,
                detail=str(e)
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Unexpected error processing the response: {str(e)}"
            )

        # Validate required fields
        required_fields = ['target_segment', 'marketing_channels', 'pricing_strategy', 'competitor_insights', 'predicted_roi']
        missing_fields = [field for field in required_fields if field not in strategy]
        if missing_fields:
            raise HTTPException(status_code=500, detail=f"Missing required fields in response: {', '.join(missing_fields)}")

        # try to extract predicted ROI numeric for storage
        predicted_roi = None
        try:
            roi_str = strategy.get('predicted_roi', '')
            if isinstance(roi_str, str) and 'x' in roi_str:
                val = roi_str.split('x')[0]
                predicted_roi = float(val)
        except ValueError:
            # Non-critical error, we'll store None for predicted_roi
            pass

        # Store in database
        try:
            db_plan = crud.create_plan(db, input_data, strategy, predicted_roi)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to store plan in database: {str(e)}")

        return {
            "success": True,
            "data": {
                "strategy": strategy,
                "db_id": db_plan.id
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@app.get('/history')
async def history(db: Session = Depends(get_db)):
    plans = crud.list_plans(db)
    return plans

@app.get("/")
async def root():
    return {"message": "Smart GTM Agent API is running!"}