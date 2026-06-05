from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.api_route import api_router
from app.services.task_manager import taskmanager

app = FastAPI(
	title = "IoT Project", description = "An IoT Project By Fast API", version="1.0.0"
)

origins = [
	"http://localhost",
	"http://localhost:8000",
	"*"
]

app.add_middleware(
	CORSMiddleware,
	allow_origins=origins,
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
	await taskmanager.start_all()

@app.get("/")
async def root():
	return {
		"status":"success",
		"message":"Connect to Raspberry Pi successfull!"
	}

app.include_router(api_router)

if __name__ == "__main__":
	import uvicorn
	uvicorn.run("app.main:app", host="0.0.0.0", port=8000, workers =1, loop="asyncio", http="httptools")
