import os
import subprocess
import tempfile
import shutil
from pathlib import Path
import requests

class GitUtils:
    
    @staticmethod
    def clone_repository(repo_url):
        """Clone repository to temporary directory"""
        try:
            # Create temporary directory
            temp_dir = tempfile.mkdtemp(prefix="codebase_genius_")
            
            # Clone repository
            result = subprocess.run(
                ["git", "clone", repo_url, temp_dir],
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                return temp_dir
            else:
                print(f"Git clone failed: {result.stderr}")
                return None
                
        except Exception as e:
            print(f"Error cloning repository: {e}")
            return None
    
    @staticmethod
    def generate_file_tree(root_path):
        """Generate structured file tree"""
        file_tree = {
            "name": os.path.basename(root_path),
            "path": root_path,
            "type": "directory",
            "children": [],
            "file_count": 0
        }
        
        def build_tree(current_path, tree_node):
            try:
                for item in os.listdir(current_path):
                    item_path = os.path.join(current_path, item)
                    
                    # Skip hidden directories and files
                    if item.startswith('.'):
                        continue
                    
                    if os.path.isdir(item_path):
                        # Skip common irrelevant directories
                        if item in ['.git', '__pycache__', 'node_modules', 'venv', 'env', '.idea']:
                            continue
                            
                        dir_node = {
                            "name": item,
                            "path": item_path,
                            "type": "directory",
                            "children": []
                        }
                        tree_node["children"].append(dir_node)
                        build_tree(item_path, dir_node)
                    else:
                        file_node = {
                            "name": item,
                            "path": item_path,
                            "type": "file",
                            "extension": os.path.splitext(item)[1]
                        }
                        tree_node["children"].append(file_node)
                        tree_node["file_count"] += 1
            except PermissionError:
                pass
        
        build_tree(root_path, file_tree)
        return file_tree
    
    @staticmethod
    def filter_irrelevant_directories(file_tree):
        """Filter out irrelevant directories from file tree"""
        irrelevant_dirs = ['.git', '__pycache__', 'node_modules', 'venv', 'env', '.idea', 'build', 'dist']
        
        def filter_tree(node):
            if node["type"] == "directory":
                node["children"] = [
                    child for child in node["children"]
                    if not (child["type"] == "directory" and child["name"] in irrelevant_dirs)
                ]
                for child in node["children"]:
                    filter_tree(child)
            return node
        
        return filter_tree(file_tree)
    
    @staticmethod
    def find_and_parse_readme(file_tree):
        """Find and read README file"""
        readme_files = ['README.md', 'README.txt', 'README', 'readme.md']
        
        def find_readme(node):
            if node["type"] == "file" and node["name"] in readme_files:
                try:
                    with open(node["path"], 'r', encoding='utf-8') as f:
                        return f.read()
                except UnicodeDecodeError:
                    try:
                        with open(node["path"], 'r', encoding='latin-1') as f:
                            return f.read()
                    except:
                        return None
                except:
                    return None
            elif node["type"] == "directory":
                for child in node["children"]:
                    content = find_readme(child)
                    if content:
                        return content
            return None
        
        return find_readme(file_tree)
    
    @staticmethod
    def get_main_directories(file_tree):
        """Identify main directories in repository"""
        main_dirs = []
        
        def collect_dirs(node, depth=0):
            if node["type"] == "directory" and depth <= 2:  # Only top 2 levels
                main_dirs.append(node["name"])
                for child in node["children"]:
                    collect_dirs(child, depth + 1)
        
        collect_dirs(file_tree)
        return main_dirs