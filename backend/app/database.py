# Updated version of the database.py file with necessary changes.

from sqlalchemy import create_engine, Column, String, Integer, ForeignKey, Date
from sqlalchemy.orm import sessionmaker, declarative_base, relationship

DATABASE_URL = "postgresql://postgres:admin@localhost/test_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# User model
class User(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, nullable=True, index=True)
    display_name = Column(String, unique=False, nullable=True, index=True)
    role = Column(String, default="player", index=True)
    phone_number = Column(String, unique=True, nullable=True, index=True)
    dob = Column(Date, nullable=True)
    position_id = Column(Integer, ForeignKey("positions.id"), nullable=True)
    location_id = Column(Integer, ForeignKey("locations.id"), nullable=True)
    position = relationship("Position", back_populates="users")
    location = relationship("Location", back_populates="users")


# Position model
class Position(Base):
    __tablename__ = "positions"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    users = relationship("User", back_populates="position")


# Location model
class Location(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    country = Column(String, nullable=False)
    state = Column(String, nullable=False)
    city = Column(String, nullable=False)
    area = Column(String, nullable=True)
    users = relationship("User", back_populates="location")


# Create tables
Base.metadata.create_all(bind=engine)


# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
