from sqlalchemy import Column, Integer, String, Text, Float, DateTime
from sqlalchemy.sql import func
from database import Base

class GTMPlan(Base):
    __tablename__ = "gtm_plans"
    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(256))
    target_audience = Column(String(512))
    budget = Column(String(64))
    region = Column(String(128))
    competitors = Column(String(512))
    strategy_json = Column(Text)
    predicted_roi = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
