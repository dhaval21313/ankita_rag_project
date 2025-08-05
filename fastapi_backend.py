from fastapi import FastAPI, Request
from pydantic import BaseModel
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_ollama import OllamaLLM
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from pathlib import Path
import uvicorn
import traceback
import os

# === CONFIG ===
INDEX_PATH = Path("/home/dhaval/ankita_rag_project/faiss_index_combined")
EMBED_MODEL = "hkunlp/instructor-large"
MODEL_NAME = "llama3"

# Force Ollama to use CPU for LLM
os.environ["CUDA_VISIBLE_DEVICES"] = ""

# === LOAD COMPONENTS ===
try:
    print("Loading embedding model...")
    try:
        embedding_model = HuggingFaceEmbeddings(model_name=EMBED_MODEL, model_kwargs={"device": "cuda:0"})
    except RuntimeError as e:
        print("⚠️ GPU out of memory, falling back to CPU...")
        embedding_model = HuggingFaceEmbeddings(model_name=EMBED_MODEL, model_kwargs={"device": "cpu"})
    
    print(f"Loading vectorstore from {INDEX_PATH}...")
    vectorstore = FAISS.load_local(INDEX_PATH, embedding_model, allow_dangerous_deserialization=True)
    
    print("Loading LLM on CPU...")
    llm = OllamaLLM(model=MODEL_NAME)
    
    retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

    # === Prompt Template ===
    custom_prompt = PromptTemplate(
        input_variables=["context", "question"],
        template="""
        You are Ankita, an experienced and friendly AI physiotherapy assistant.
        Based on the following documents and knowledge, answer the question clearly and concisely.

        Context:
        {context}

        Question:
        {question}

        Helpful Answer with supporting sources:
        """.strip()
    )

    # === Retrieval QA Chain ===
    qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=retriever,
        return_source_documents=True,
        chain_type_kwargs={"prompt": custom_prompt}
    )
except Exception as e:
    print(f"❌ Failed to initialize components: {e}")
    raise

# === FASTAPI SETUP ===
app = FastAPI(title="Ankita - Physio Assistant")

class QueryRequest(BaseModel):
    question: str

@app.post("/query")
async def query_pdf(data: QueryRequest):
    try:
        result = qa_chain.invoke(data.question)
        answer = result["result"]
        sources = [
            {
                "source": Path(doc.metadata.get("source", "Unknown")).name,
                "page": doc.metadata.get("page", "N/A")
            }
            for doc in result["source_documents"]
        ]
        return {"answer": answer, "sources": sources}
    except Exception as e:
        print(f"❌ Error processing query: {e}")
        print(traceback.format_exc())
        return {"error": f"Failed to process query: {str(e)}"}

@app.get("/")
def read_root():
    return {"message": "Ankita backend is running."}

if __name__ == "__main__":
    uvicorn.run("fastapi_backend:app", host="0.0.0.0", port=8000, reload=True)
