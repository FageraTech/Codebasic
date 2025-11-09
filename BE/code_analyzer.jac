jac CodeAnalyzer {
    import { graph, walker } with 'std';
    import { parser_utils } with '../parser_utils.py';
    
    node code_analyzer_node {
        has name = "Code Analyzer";
        has capabilities = ["parsing", "graph_building", "relationship_analysis"];
    }
    
    walker build_code_context_graph {
        has input prioritized_files, file_tree;
        has output code_graph;
        
        can parser_utils.parse_file;
        can parser_utils.extract_functions;
        can parser_utils.extract_classes;
        can parser_utils.build_relationships;
        
        with entry {
            code_graph = {
                "nodes": {},
                "edges": [],
                "file_dependencies": {}
            };
            
            std.log("Building Code Context Graph for " + prioritized_files.length.toString() + " files");
            
            
            for file_info in prioritized_files {
                std.log("Analyzing: " + file_info.path);
                
                file_analysis = parser_utils:parse_file(file_info);
                
                if file_analysis {
                    
                    code_graph.nodes[file_info.path] = {
                        "type": "file",
                        "name": file_info.name,
                        "functions": file_analysis.functions,
                        "classes": file_analysis.classes,
                        "imports": file_analysis.imports
                    };
                    
                
                    relationships = parser_utils:build_relationships(file_analysis, file_tree);
                    code_graph.edges.extend(relationships.edges);
                    code_graph.file_dependencies[file_info.path] = relationships.dependencies;
                }
            }
            
            std.log("Code Context Graph built with " + 
                   code_graph.nodes.length.toString() + " nodes and " + 
                   code_graph.edges.length.toString() + " edges");
        }
    }
    
    walker prioritize_files {
        has input file_tree;
        has output prioritized_files;
        
        with entry {
            prioritized_files = [];
            entry_points = [];
            modules = [];
            tests = [];
            utilities = [];
            
            for file in file_tree.files {
                file_path = file.path.toLowerCase();
                file_name = file.name.toLowerCase();
                
                
                if (file_name in ["main.py", "app.py", "main.jac"] or
                    "main" in file_name and file.extension in ["py", "jac"]) {
                    entry_points.append(file);
                }
                
                else if (any(term in file_path for term in ["/src/", "/lib/", "/core/", "/app/"])) {
                    modules.append(file);
                }
                

                else if (file_name in ["__init__.py", "setup.py", "requirements.txt", "config.py"]) {
                    modules.append(file);
                }
                
                else if ("test" in file_path or "spec" in file_path) {
                    tests.append(file);
                }
            
                else {
                    utilities.append(file);
                }
            }
            
            prioritized_files = entry_points + modules + utilities + tests;
        }
    }
    
    walker get_highly_connected_modules {
        has input code_graph;
        has output connected_modules;
        
        with entry {
            connected_modules = [];
            connection_counts = {};
            
            
            for edge in code_graph.edges {
                source_file = edge.source.split('/').slice(0, -1).join('/');
                if source_file in connection_counts {
                    connection_counts[source_file] += 1;
                } else {
                    connection_counts[source_file] = 1;
                }
            }
            
            
            sorted_modules = connection_counts.keys().sort(
                key=lambda x: connection_counts[x], 
                reverse=true
            );
            
            connected_modules = sorted_modules.slice(0, 10); 
        }
    }
    
    walker query_relationships {
        has input query, code_graph;
        has output results;
        
        with entry {
            results = [];
            query_lower = query.lower();
            
            for node_path, node_data in code_graph.nodes {
                
                for func in node_data.functions {
                    if (query_lower in func.name.lower() or
                        any(query_lower in call.lower() for call in func.calls)) {
                        results.append({
                            "type": "function",
                            "file": node_path,
                            "function": func.name,
                            "calls": func.calls
                        });
                    }
                }
                
                
                for cls in node_data.classes {
                    if (query_lower in cls.name.lower() or
                        any(query_lower in parent.lower() for parent in cls.parent_classes)) {
                        results.append({
                            "type": "class",
                            "file": node_path,
                            "class": cls.name,
                            "parents": cls.parent_classes
                        });
                    }
                }
            }
        }
    }
}