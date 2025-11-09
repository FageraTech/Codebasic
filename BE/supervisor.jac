jac Supervisor {
    import { repo_mapper, code_analyzer, doc_genie } with './';
    import { graph, walker } with 'std';
    
    node supervisor_node {
        has name = "Code Genius Supervisor";
        has status = "idle";
        has current_repository;
    }
    
    walker generate_documentation_workflow {
        has input repo_url;
        has output documentation_result;
        
        can repo_mapper.clone_and_map_repository;
        can repo_mapper.summarize_readme;
        can code_analyzer.build_code_context_graph;
        can doc_genie.generate_final_documentation;
        can code_analyzer.prioritize_files;
        
        with entry {
           
            std.log("Step 1: Cloning and mapping repository");
            file_tree = repo_mapper:clone_and_map_repository(repo_url);
            readme_summary = repo_mapper:summarize_readme(file_tree);
            
            
            std.log("Step 2: Prioritizing files for analysis");
            prioritized_files = code_analyzer:prioritize_files(file_tree);
            
            
            std.log("Step 3: Building Code Context Graph");
            code_graph = code_analyzer:build_code_context_graph(prioritized_files, file_tree);
            
            
            std.log("Step 4: Generating final documentation");
            documentation_result = doc_genie:generate_final_documentation(
                file_tree, 
                readme_summary, 
                code_graph, 
                repo_url
            );
            
            std.log("Workflow completed successfully");
        }
    }
    
    walker orchestrate_analysis {
        has input file_tree, code_graph;
        has output analysis_plan;
        
        with entry {
            
            entry_points = [];
            for file in file_tree.files {
                if file.name in [ "app.py",  "main.jac"] {
                    entry_points.append(file);
                }
            }
            
            
            analysis_plan = {
                "phase_1": entry_points,
                "phase_2": code_analyzer:get_highly_connected_modules(code_graph),
                "phase_3": "remaining_files"
            };
        }
    }
} 