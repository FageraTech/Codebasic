import streamlit as st
import requests
import json
import time

st.set_page_config(
    page_title="FageraTech Codebase Genius",
    page_icon="📚",
    layout="wide"
)

st.title("📚 FageraTech Codebase Genius")
st.subheader("Agentic Code Documentation System")

# Sidebar for configuration
with st.sidebar:
    st.header("Configuration")
    api_url = st.text_input(
        "Backend API URL",
        value="http://localhost:8000",
        help="URL of the running Jac backend server"
    )
    

# Main interface
col1, col2 = st.columns([2, 1])

with col1:
    st.header("Generate Documentation")
    
    github_url = st.text_input(
        "GitHub Repository URL",
        placeholder="https://github.com/username/repository",
        help="Enter the full URL of the public GitHub repository"
    )
    
    if st.button("Generate Documentation", type="primary"):
        if github_url:
            with st.spinner("Starting documentation generation..."):
                try:
                    # Call the backend API
                    response = requests.post(
                        f"{api_url}/generate_docs",
                        json={"github_url": github_url}
                    )
                    
                    if response.status_code == 200:
                        result = response.json()
                        task_id = result.get("task_id")
                        
                        st.success(f"Documentation generation started! Task ID: {task_id}")
                        
                        # Poll for completion
                        progress_bar = st.progress(0)
                        status_text = st.empty()
                        
                        for i in range(10):
                            time.sleep(2)
                            
                            # Check status
                            status_response = requests.get(
                                f"{api_url}/status/{task_id}"
                            )
                            
                            if status_response.status_code == 200:
                                status_data = status_response.json()
                                progress = status_data.get("progress", 0)
                                current_status = status_data.get("status", "processing")
                                
                                progress_bar.progress(progress)
                                status_text.text(f"Status: {current_status} ({progress}%)")
                                
                                if current_status == "completed":
                                    doc_path = status_data.get("documentation_path")
                                    st.success(f"Documentation generated successfully!")
                                    
                                    # Show download link
                                    st.download_button(
                                        label="Download Documentation",
                                        data=open(doc_path, "r").read() if doc_path else "# Documentation",
                                        file_name="generated_docs.md",
                                        mime="text/markdown"
                                    )
                                    break
                                elif current_status == "error":
                                    st.error(f"Error: {status_data.get('error', 'Unknown error')}")
                                    break
                    else:
                        st.error(f"Failed to start documentation generation: {response.text}")
                        
                except requests.exceptions.ConnectionError:
                    st.error("Could not connect to the backend server. Make sure the Jac server is running.")
                except Exception as e:
                    st.error(f"An error occurred: {str(e)}")
        else:
            st.warning("Please enter a GitHub repository URL")



# Footer
st.markdown("---")
st.markdown("Built with using Jac Language and Streamlit")
