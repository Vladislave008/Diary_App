from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import List
import uvicorn
from fastapi.middleware.cors import CORSMiddleware

DATABASE_URL = "sqlite:///./test.db"  

app = FastAPI()

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["172.25.0.7"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(String, index=True)
    owner_id = Column(String, index=True) 
    tab_name = Column(String, index=True)

class ItemCreate(BaseModel):
    text: str
    owner_id: str
    tab_name: str

class ItemResponse(BaseModel):
    id: int
    text: str
    tab_name: str

    class Config:
        orm_mode = True

@app.options("/items/")
async def options_items():
    return {"allowed_methods": ["GET", "POST"]}
    
@app.post("/items/", response_model=ItemResponse)
async def create_item(item: ItemCreate):
    db: Session = SessionLocal()
    db_item = Item(text=item.text, owner_id=item.owner_id, tab_name=item.tab_name) 
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.get("/items/", response_model=List[ItemResponse])
async def read_items(owner_id: str):
    db: Session = SessionLocal()
    items = db.query(Item).filter(Item.owner_id == owner_id).all() 
    return items


@app.delete("/items/{item_name}", status_code=204)
async def delete_item(item_name: str, owner_id: str, tab_name: str):
    db: Session = SessionLocal()


    item_to_delete = db.query(Item).filter(Item.text == item_name, Item.owner_id == owner_id, Item.tab_name == tab_name).first()

    if item_to_delete is None:
        raise HTTPException(status_code=404, detail="Item not found")

    db.delete(item_to_delete)
    db.commit()

class Tab(Base):
    __tablename__ = "tabs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    owner_id = Column(String, index=True)  

class TabCreate(BaseModel):
    name: str
    owner_id: str

class TabResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        orm_mode = True
        
@app.post("/tabs/", response_model=TabResponse)
async def create_tab(tab: TabCreate):
    db: Session = SessionLocal()
    db_tab = Tab(name=tab.name, owner_id=tab.owner_id)
    db.add(db_tab)
    db.commit()
    db.refresh(db_tab)
    return db_tab

@app.get("/tabs/", response_model=List[TabResponse])
async def read_tabs(owner_id: str):
    db: Session = SessionLocal()
    tabs = db.query(Tab).filter(Tab.owner_id == owner_id).all()
    return tabs

@app.delete("/tabs/{tab_name}", status_code=204)
async def delete_tab(tab_name: str, owner_id: str):
    db: Session = SessionLocal()

    # Удаляем все элементы с tab_name
    db.query(Item).filter(Item.tab_name == tab_name, Item.owner_id == owner_id).delete(synchronize_session=False)
    db.commit()

    # Удаляем таб
    deleted_tab = db.query(Tab).filter(Tab.name == tab_name, Tab.owner_id == owner_id).first()
    if not deleted_tab:
        raise HTTPException(status_code=404, detail="Tab not found")

    db.delete(deleted_tab)
    db.commit()

Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, log_level="info")
    
# python C:/Users/BAAL/Desktop/diary_app/lib/main.py
# adb connect 172.25.0.9:5555