jac RepoMapper {
    import { graph, walker } with 'std';
    import { git_utils } with '../utils.py';
    
    node repo_mapper_node {
        has name = "Repo Mapper";
        has capabilities = ["clone", "file_tree", "readme_analysis"];
    }
    
    walker clone_and_map_repository {
        has input repo_url;
        has output file_tree;
        
        can git_utils.clone_repository;
        can git_utils.generate_file_tree;
        
        with entry {
            std.log("Cloning repository: " + repo_url);
            
            // Clone repository
            local_path = git_utils:clone_repository(repo_url);
            
            if local_path == null {
                std.err("Failed to clone repository");
                file_tree = {};
                return;
            }
            
            

            file_tree = git_utils:generate_file_tree(local_path);
            
            

            file_tree = git_utils:filter_irrelevant_directories(file_tree);
            
            std.log("Repository mapped successfully. Files found: " + file_tree.file_count.toString());
        }
    }
    
    walker summarize_readme {
        has input file_tree;
        has output readme_summary;
        
        can git_utils.find_and_parse_readme;
        
        with entry {
            readme_content = git_utils:find_and_parse_readme(file_tree);
            
            if readme_content {
               

                readme_summary = llm:summarize_text(readme_content, {
                    "prompt": "Summarize this README file concisely, highlighting the project's purpose, key features, and main usage."
                });
            } else {
                readme_summary = "No README file found in the repository.";
            }
            
            std.log("README summary generated");
        }
    }
    
    walker get_repo_structure {
        has input file_tree;
        has output structure_analysis;
        
        with entry {
            structure_analysis = {
                "total_files": file_tree.file_count,
                "file_types": {},
                "main_directories": []
            };
            
            // Analyze file types

            for file in file_tree.files {
                extension = file.extension;
                if extension in structure_analysis.file_types {
                    structure_analysis.file_types[extension] += 1;
                } else {
                    structure_analysis.file_types[extension] = 1;
                }
            }
            
            
            structure_analysis.main_directories = git_utils:get_main_directories(file_tree);
        }
    }
}