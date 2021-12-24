
## Notes about Dart Analysis Server (DAS):
> WIP: just trying to document what I learned so far. 

### Available packages/tools:
When it comes to static analysis in dart, the sdk has multiple packages (located within [sdk/pkg](https://github.com/dart-lang/sdk/tree/main/pkg)) for different use cases:
- analyzer
    - The package provides a library that performs static analysis of Dart code.  
- analysis_server
    - a long-running process that provides analysis results to other tools. 
    - cannot be used as a package.  
- analysis_server_client
    - analysis_server_client is a client wrapper over Analysis Server. 
    - can be used as a package. 
- analyzer_plugin 
    - A framework for building plugins for the analysis server.
    - Useful for developing analysis metrics for an IDE (see [dart_code_metrics](https://pub.dev/packages/dart_code_metrics) which usesit.
- and few other packages

Useful links:
- [Language Server Protocol API](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html)
- [Language Server Portocol (LSP) Spec for Dart](https://github.com/dart-lang/sdk/tree/master/pkg/analysis_server/tool/lsp_spec)

### Why Using the Anaylsis Server?

While the analyzer package is helpful in parsing dart code as an AST, it doesn't provide analytical capabilities by default. To perform analysis, one need to utilize the analysis server with such tasks either by using the [DAS protocol](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html) or [LSP portocol](https://github.com/dart-lang/sdk/tree/master/pkg/analysis_server/tool/lsp_spec) (i.e. the one used by VS code and Dart-Code extension).   

> a server can be simply created using dart running: `dart language-server`. It uses `stdio` for communication and `LSP` is the default protocol. See the `Server` class in `analysis_server_client` package or `Drive` class in `analysis_server` package for how the server is initialized. The `analysis_server_client` [example](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_client/example/example.dart) is a also good start to understand how to work with the server. 

For instance, trying to find all the top level declarations, one can use the `analyzer` package but they'll need to parse the AST for every "file" in the project and visit every AST to collect top level declaration. On the other hand, using the Protocol, one can spin an analysis-server, query [search.findTopLevelDeclarations](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findTopLevelDeclarations), and they'll get the results. 

> The `analysis_server` has its own [SearchEngine](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/lib/src/services/search/search_engine.dart#L43) which works on a project level and helps the protcol to expose such queries. 

Extending on the example, if one needs to find all the unused top level declaration, [search.findElementReferences](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findElementReferences) can be executed on all the top level declarations to find if they've any references. This is only possible with the `analysis_server`.  


## Other Notes:

- The analysis server doesn't seem to have a way to stop analyzing errors. The server automatically ignores whatever is defined in `analysis_options.yaml`[analyzer][exclude] and `dot` folder (e.g. `.vscode`) (see the protocol if there are more). Since we are only interested in sending query for a given field in a given project directory, it would be logical to turn off errro analysis. Maybe excluding the entire project is the easiest option (as long as the server doesn't read analysis_options on its own) -- need to verify. 

- [search.findTopLevelDeclarations](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findTopLevelDeclarations) searches the entire project and its packages (seen results coming from `~/.pub_cache). Need to find if there's a way to scope the search to the root directory. 



