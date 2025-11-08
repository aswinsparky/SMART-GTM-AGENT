from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class GTMInput(BaseModel):
    product_name: str
    target_audience: str
    budget: str
    region: str
    competitors: Optional[str] = ""

class MarketingChannel(BaseModel):
    channel: str
    strategy: str
    budget_allocation: str
    expected_impact: str

class TargetSegment(BaseModel):
    primary_audience: str
    demographics: str
    psychographics: str
    pain_points: str

class PricingStrategy(BaseModel):
    model: str
    rationale: str
    competitive_positioning: str
    target_margins: str

class CompetitorInsights(BaseModel):
    main_competitors: List[str]
    competitive_advantages: List[str]
    market_gaps: str
    defense_strategy: str

class PredictedROI(BaseModel):
    expected_return: str
    timeline: str
    key_metrics: List[str]
    risk_factors: List[str]

class GTMStrategy(BaseModel):
    target_segment: TargetSegment
    marketing_channels: List[MarketingChannel]
    pricing_strategy: PricingStrategy
    competitor_insights: CompetitorInsights
    predicted_roi: PredictedROI

class GTMPlanDB(BaseModel):
    id: int
    product_name: str
    target_audience: str
    budget: str
    region: str
    competitors: Optional[str]
    strategy_json: str
    predicted_roi: Optional[float]
    created_at: datetime

    class Config:
        orm_mode = True
