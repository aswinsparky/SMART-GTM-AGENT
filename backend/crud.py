from sqlalchemy.orm import Session
import models, schemas
import json

def create_plan(db: Session, input_data: schemas.GTMInput, strategy_json: dict, predicted_roi: float | None):
    db_plan = models.GTMPlan(
        product_name=input_data.product_name,
        target_audience=input_data.target_audience,
        budget=input_data.budget,
        region=input_data.region,
        competitors=input_data.competitors or "",
        strategy_json=json.dumps(strategy_json),
        predicted_roi=predicted_roi
    )
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)
    return db_plan

def list_plans(db: Session, skip: int = 0, limit: int = 50):
    return db.query(models.GTMPlan).order_by(models.GTMPlan.created_at.desc()).offset(skip).limit(limit).all()
