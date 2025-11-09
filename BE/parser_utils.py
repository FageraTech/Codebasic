import ast
import os
from typing import Dict, List, Any
import tree_sitter
from tree_sitter import Language, Parser

class ParserUtils:
    
    def __init__(self):
        self.python_parser = self._setup_python_parser()
    
    def _setup_python_parser(self):
        """Setup Tree-sitter Python parser"""
        try:
            # Try to load built-in parser
            PYTHON_LANGUAGE = Language('build/languages.so', 'python')
            parser = Parser()
            parser.set_language(PYTHON_LANGUAGE)
            return parser
        except:
            # Fallback to AST parser
            return None
    
    def parse_file(self, file_info):
        """Parse a source code file"""
        file_path = file_info["path"]
        file_extension = file_info.get("extension", "")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            try:
                with open(file_path, 'r', encoding='latin-1') as f:
                    content = f.read()
            except:
                return None
        
        if file_extension == '.py':
            return self._parse_python_file(content, file_path)
        elif file_extension == '.jac':
            return self._parse_jac_file(content, file_path)
        else:
            return self._parse_generic_file(content, file_path)
    
    def _parse_python_file(self, content, file_path):
        """Parse Python file using AST"""
        try:
            tree = ast.parse(content)
            
            analysis = {
                "functions": [],
                "classes": [],
                "imports": [],
                "file_path": file_path
            }
            
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    func_info = {
                        "name": node.name,
                        "signature": self._get_function_signature(node),
                        "docstring": ast.get_docstring(node),
                        "parameters": self._get_function_parameters(node),
                        "line_number": node.lineno
                    }
                    analysis["functions"].append(func_info)
                
                elif isinstance(node, ast.ClassDef):
                    class_info = {
                        "name": node.name,
                        "docstring": ast.get_docstring(node),
                        "methods": [],
                        "parent_classes": [base.id for base in node.bases if isinstance(base, ast.Name)],
                        "line_number": node.lineno
                    }
                    
                    # Extract methods
                    for item in node.body:
                        if isinstance(item, ast.FunctionDef):
                            method_info = {
                                "name": item.name,
                                "signature": self._get_function_signature(item),
                                "docstring": ast.get_docstring(item)
                            }
                            class_info["methods"].append(method_info)
                    
                    analysis["classes"].append(class_info)
                
                elif isinstance(node, (ast.Import, ast.ImportFrom)):
                    import_info = {
                        "module": node.names[0].name if isinstance(node, ast.Import) else node.module,
                        "names": [alias.name for alias in node.names],
                        "line_number": node.lineno
                    }
                    analysis["imports"].append(import_info)
            
            return analysis
            
        except SyntaxError:
            return None
    
    def _parse_jac_file(self, content, file_path):
        """Parse Jac file (simplified)"""
        # Basic Jac parsing - can be extended
        analysis = {
            "functions": [],
            "classes": [],
            "imports": [],
            "file_path": file_path
        }
        
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line = line.strip()
            
            # Detect walkers (similar to functions)
            if line.startswith('walker '):
                parts = line.split()
                if len(parts) >= 2:
                    func_info = {
                        "name": parts[1],
                        "signature": line,
                        "docstring": self._extract_jac_docstring(lines, i),
                        "parameters": self._extract_jac_parameters(line),
                        "line_number": i + 1
                    }
                    analysis["functions"].append(func_info)
            
            # Detect nodes (similar to classes)
            elif line.startswith('node '):
                parts = line.split()
                if len(parts) >= 2:
                    class_info = {
                        "name": parts[1],
                        "docstring": self._extract_jac_docstring(lines, i),
                        "methods": [],
                        "parent_classes": [],
                        "line_number": i + 1
                    }
                    analysis["classes"].append(class_info)
        
        return analysis
    
    def _parse_generic_file(self, content, file_path):
        """Parse generic file type"""
        return {
            "functions": [],
            "classes": [],
            "imports": [],
            "file_path": file_path,
            "content_preview": content[:500] + "..." if len(content) > 500 else content
        }
    
    def _get_function_signature(self, func_node):
        """Extract function signature"""
        args = [arg.arg for arg in func_node.args.args]
        return f"def {func_node.name}({', '.join(args)})"
    
    def _get_function_parameters(self, func_node):
        """Extract function parameters"""
        params = []
        for arg in func_node.args.args:
            param_info = {
                "name": arg.arg,
                "type": "Any"  # Can be enhanced with type hints
            }
            params.append(param_info)
        return params
    
    def _extract_jac_docstring(self, lines, start_line):
        """Extract docstring from Jac code"""
        docstring = ""
        for i in range(start_line + 1, min(start_line + 10, len(lines))):
            line = lines[i].strip()
            if line.startswith('/*') or line.startswith('#'):
                docstring += line + "\n"
            else:
                break
        return docstring.strip() if docstring else None
    
    def _extract_jac_parameters(self, line):
        """Extract parameters from Jac walker definition"""
        # Simplified parameter extraction
        if '(' in line and ')' in line:
            param_str = line.split('(', 1)[1].split(')')[0]
            params = [p.strip() for p in param_str.split(',') if p.strip()]
            return [{"name": p, "type": "Any"} for p in params]
        return []
    
    def build_relationships(self, file_analysis, file_tree):
        """Build relationships between code elements"""
        relationships = {
            "edges": [],
            "dependencies": []
        }
        
        # Extract imports as dependencies
        for import_stmt in file_analysis.get("imports", []):
            relationships["dependencies"].append({
                "type": "import",
                "module": import_stmt.get("module"),
                "imports": import_stmt.get("names", [])
            })
        
        # Build call relationships (simplified)
        for func in file_analysis.get("functions", []):
            # This is a simplified approach - real implementation would analyze function bodies
            func_name = func["name"]
            relationships["edges"].append({
                "source": file_analysis["file_path"],
                "target": f"function:{func_name}",
                "type": "defines"
            })
        
        return relationships