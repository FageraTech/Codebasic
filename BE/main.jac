jac CodebaseGenius {
    import { supervisor, repo_mapper, code_analyzer, doc_genie } with './agents/';
    import { graph, walker } with 'std';
    
    node repository {
        has name;
        has url;
        has local_path;
        has file_tree;
        has readme_summary;
        has code_graph;
        has documentation;
        has created_at;
    }
    
    node code_file {
        has name;
        has path;
        has language;
        has content;
        has ast;
        has functions;
        has classes;
        has imports;
    }
    
    node function_node {
        has name;
        has signature;
        has docstring;
        has parameters;
        has return_type;
        has calls = [];
    }
    
    node class_node {
        has name;
        has methods = [];
        has parent_classes = [];
        has attributes = [];
    }
    
    edge code_contains;
    edge calls;
    edge inherits;
    edge imports;
    
    graph codebase_graph {
        has anchor repository_node;
    }
    
    walker init {
        root {
            spawn here --> graph::codebase_graph;
            std.log("Codebase Genius initialized");
        }
    }
    
    walker generate_documentation {
        has input url;
        has output result;
        
        can supervisor.generate_documentation_workflow;
        
        with entry {
            report "Starting documentation generation for: " + url;
            result = supervisor:generate_documentation_workflow(url);
            report "Documentation generation completed";
        }
    }
    
    walker health {
        report "Codebase Genius is running";
        report "Agents: Supervisor, Repo Mapper, Code Analyzer, DocGenie";
    }
}