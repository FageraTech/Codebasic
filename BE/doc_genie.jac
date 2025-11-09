jac DocGenie {
    import { graph, walker } with 'std';
    import { diagram_generator } with '../utils/diagram_generator.py';
    
    node doc_genie_node {
        has name = "DocGenie";
        has capabilities = ["markdown_generation", "diagram_creation", "documentation_assembly"];
    }
    
    walker generate_final_documentation {
        has input file_tree, readme_summary, code_graph, repo_url;
        has output documentation;
        
        can diagram_generator.generate_class_diagram;
        can diagram_generator.generate_function_call_graph;
        can generate_markdown_sections;
        
        with entry {
            std.log("Assembling final documentation");
            
            // Generate diagrams
            class_diagram = diagram_generator:generate_class_diagram(code_graph);
            call_graph = diagram_generator:generate_function_call_graph(code_graph);
            
            // Generate markdown sections
            documentation = generate_markdown_sections(
                repo_url, 
                readme_summary, 
                file_tree, 
                code_graph, 
                class_diagram, 
                call_graph
            );
            
            // Save documentation
            save_documentation(repo_url, documentation);
            
            std.log("Documentation generated and saved successfully");
        }
    }
    
    walker generate_markdown_sections {
        has input repo_url, readme_summary, file_tree, code_graph, class_diagram, call_graph;
        has output markdown;
        
        with entry {
            repo_name = repo_url.split('/').slice(-1)[0];
            
            markdown = "# " + repo_name + " Documentation\n\n";
            
            // Table of Contents
            markdown += "## Table of Contents\n";
            markdown += "- [Project Overview](#project-overview)\n";
            markdown += "- [Repository Structure](#repository-structure)\n";
            markdown += "- [Installation](#installation)\n";
            markdown += "- [Usage](#usage)\n";
            markdown += "- [API Reference](#api-reference)\n";
            markdown += "- [Architecture](#architecture)\n";
            markdown += "- [Code Analysis](#code-analysis)\n\n";
            
            // Project Overview
            markdown += "## Project Overview\n\n";
            markdown += readme_summary + "\n\n";
            markdown += "**Repository URL**: " + repo_url + "\n\n";
            
            // Repository Structure
            markdown += "## Repository Structure\n\n";
            markdown += "```\n";
            markdown += generate_file_tree_markdown(file_tree);
            markdown += "```\n\n";
            
            // Installation
            markdown += "## Installation\n\n";
            markdown += generate_installation_section(file_tree);
            
            // Usage
            markdown += "## Usage\n\n";
            markdown += generate_usage_examples(code_graph);
            
            // API Reference
            markdown += "## API Reference\n\n";
            markdown += generate_api_reference(code_graph);
            
            // Architecture
            markdown += "## Architecture\n\n";
            markdown += "### Class Diagram\n\n";
            markdown += "```mermaid\n";
            markdown += class_diagram;
            markdown += "\n```\n\n";
            
            markdown += "### Function Call Graph\n\n";
            markdown += "```mermaid\n";
            markdown += call_graph;
            markdown += "\n```\n\n";
            
            // Code Analysis
            markdown += "## Code Analysis\n\n";
            markdown += generate_code_analysis_summary(code_graph);
        }
    }
    
    walker save_documentation {
        has input repo_url, documentation;
        
        can std.file.write;
        
        with entry {
            repo_name = repo_url.split('/').slice(-1)[0].replace('.git', '');
            filename = "./outputs/" + repo_name + "/docs.md";
            
            // Create directory if it doesn't exist
            std.file.mkdir("./outputs/" + repo_name);
            
            // Write documentation
            std.file.write(filename, documentation);
            
            std.log("Documentation saved to: " + filename);
        }
    }
    
    walker generate_file_tree_markdown {
        has input file_tree;
        has output tree_markdown;
        
        with entry {
            tree_markdown = "";
            
            walker build_tree {
                with entry {
                    for item in file_tree.children {
                        if item.type == "directory" {
                            tree_markdown += item.name + "/\n";
                            take --> node::item;
                        } else {
                            tree_markdown += "├── " + item.name + "\n";
                        }
                    }
                }
            }
            
            spawn here walker::build_tree;
        }
    }
    
    walker generate_installation_section {
        has input file_tree;
        has output installation_section;
        
        with entry {
            installation_section = "";
            
            // Check for common installation files
            if any(file.name == "requirements.txt" for file in file_tree.files) {
                installation_section += "### Using pip\n\n";
                installation_section += "```bash\npip install -r requirements.txt\n```\n\n";
            }
            
            if any(file.name == "setup.py" for file in file_tree.files) {
                installation_section += "### Using setup.py\n\n";
                installation_section += "```bash\npython setup.py install\n```\n\n";
            }
            
            if any(file.name == "package.json" for file in file_tree.files) {
                installation_section += "### Using npm\n\n";
                installation_section += "```bash\nnpm install\n```\n\n";
            }
            
            if installation_section == "" {
                installation_section = "Please refer to the repository's README for installation instructions.\n\n";
            }
        }
    }
    
    walker generate_api_reference {
        has input code_graph;
        has output api_reference;
        
        with entry {
            api_reference = "";
            
            // Group by file
            for file_path, file_data in code_graph.nodes {
                if file_data.functions.length > 0 or file_data.classes.length > 0 {
                    api_reference += "### " + file_path + "\n\n";
                    
                    // Classes
                    for cls in file_data.classes {
                        api_reference += "#### Class: " + cls.name + "\n\n";
                        if cls.docstring {
                            api_reference += cls.docstring + "\n\n";
                        }
                        
                        // Methods
                        if cls.methods.length > 0 {
                            api_reference += "**Methods**:\n\n";
                            for method in cls.methods {
                                api_reference += "- `" + method.signature + "`\n";
                                if method.docstring {
                                    api_reference += "  - " + method.docstring + "\n";
                                }
                            }
                            api_reference += "\n";
                        }
                    }
                    
                    // Functions
                    for func in file_data.functions {
                        api_reference += "#### Function: " + func.name + "\n\n";
                        api_reference += "```python\n" + func.signature + "\n```\n\n";
                        if func.docstring {
                            api_reference += func.docstring + "\n\n";
                        }
                        
                        if func.parameters.length > 0 {
                            api_reference += "**Parameters**:\n\n";
                            for param in func.parameters {
                                api_reference += "- `" + param.name + "`: " + param.type + "\n";
                            }
                            api_reference += "\n";
                        }
                    }
                }
            }
        }
    }
}