class DiagramGenerator:
    
    @staticmethod
    def generate_class_diagram(code_graph):
        """Generate Mermaid class diagram"""
        mermaid_code = "classDiagram\n"
        
        classes_added = set()
        
        for file_path, file_data in code_graph.nodes.items():
            for class_info in file_data.get("classes", []):
                class_name = class_info["name"]
                if class_name not in classes_added:
                    classes_added.add(class_name)
                    
                    # Add class definition
                    mermaid_code += f"    class {class_name} {{\n"
                    
                    # Add methods
                    for method in class_info.get("methods", []):
                        mermaid_code += f"        {method['signature']}\n"
                    
                    mermaid_code += "    }\n"
                    
                    # Add inheritance
                    for parent in class_info.get("parent_classes", []):
                        mermaid_code += f"    {parent} <|-- {class_name}\n"
        
        return mermaid_code
    
    @staticmethod
    def generate_function_call_graph(code_graph):
        """Generate Mermaid function call graph"""
        mermaid_code = "graph TD\n"
        
        # Group functions by file
        file_functions = {}
        for file_path, file_data in code_graph.nodes.items():
            file_name = file_path.split('/')[-1]
            file_functions[file_name] = [
                f["name"] for f in file_data.get("functions", [])
            ]
        
        # Create nodes for files and functions
        for file_name, functions in file_functions.items():
            mermaid_code += f"    subgraph {file_name}\n"
            for func in functions:
                mermaid_code += f"        {file_name}_{func}[{func}]\n"
            mermaid_code += "    end\n"
        
        # Add call relationships (simplified - real implementation would analyze actual calls)
        for file_path, file_data in code_graph.nodes.items():
            file_name = file_path.split('/')[-1]
            for func in file_data.get("functions", []):
                # This is a placeholder - real call analysis would go here
                if func.get("calls"):
                    for call in func["calls"]:
                        mermaid_code += f"    {file_name}_{func['name']} --> {call}\n"
        
        return mermaid_code
    
    @staticmethod
    def generate_architecture_diagram(file_tree, code_graph):
        """Generate architecture overview diagram"""
        mermaid_code = "graph TB\n"
        mermaid_code += "    A[Codebase Genius] --> B[Repository Analysis]\n"
        mermaid_code += "    B --> C[File Structure]\n"
        mermaid_code += "    B --> D[Code Analysis]\n"
        mermaid_code += "    C --> E[Documentation]\n"
        mermaid_code += "    D --> E\n"
        
        # Add file statistics
        total_files = file_tree.get("file_count", 0)
        mermaid_code += f"    F[Total Files: {total_files}] --> E\n"
        
        return mermaid_code