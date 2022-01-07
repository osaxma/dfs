<!-- TODO: !!!!! SPELL CHECK !!!!!! -->
## Notes about Dart Analysis Server (DAS):
> WIP: just trying to document what I learned so far. 

### Dart Analysis Tools and Packages:
When it comes to static analysis in dart, the sdk has multiple packages (located within [sdk/pkg](https://github.com/dart-lang/sdk/tree/main/pkg)) for different use cases:
- analyzer
    - The package provides a library that performs static analysis of Dart code.  
- analysis_server
    - a long-running process that provides analysis results to other tools. 
    - It's not intended to be used as a package but as a server.  
- analysis_server_client
    - analysis_server_client is a client wrapper over the analysis Server. 
    - can be used as a package and it uses `DAS` protocol only (more details below). 
- analyzer_plugin 
    - A framework for building plugins for the analysis server.
    - Useful for developing analysis metrics for an IDE (see [dart_code_metrics](https://pub.dev/packages/dart_code_metrics) which uses it and provide a great example.
- and few other packages


### What's the goal here?
There were two goals in mind: finding unused packages and finding unused top level declarations within a dart/flutter project. The approach to each goal is described below:
    
- How can I find all unused packages within a project?

    The first goal can be acheived with pretty much any programming language since one can parse all the packages defined in `pubspec.yaml`, and then see if they've any references in `lib` directory by simply searching for: `package:<package_name>` string. Also, the `analyzer` package can be used here by creating an `ImportVisitor` that visits every import declarative for every `.dart` file within the lib directory and compare them to the ones parsed from `pubspec.yaml`. 

    ```dart
    class ImportVisitor extends SimpleAstVisitor {
        final imports = <String>[];
        @override
        visitImportDirective(ImportDirective node) {
            /* read and collect imports here */
            imports.add(node.uri.stringValue);
        }
    }
    ```

    Now one can do a simple check between the packages from `ImportVisitor.imports` and those from from `pubspec.yaml` to see what's used and what's not.
    

- How can I find all unused top level declarations within a project?

    Again, one needs to first find all the top level declaration based on the Dart language grammar then search for any references for these declarations. While one can use the visitor approach from the `analyzer` package (i.e. `SimpleAstVisitor.visitTopLevelVariableDeclaration`), and collect all the top level declarations, how can one search for their references? 

    If one digs deep into the `analysis_server` pacakge, they'll find a class called [`SearchEngine`](https://github.com/dart-lang/sdk/blob/edbf6300a13095e164a876ee33251ec91fea072f/pkg/analysis_server/lib/src/services/search/search_engine.dart#L43). The search engine has exactly what we need `searchReferences` as well as `searchTopLevelDeclarations` (so no need to visit the ast and collect top level declarations manually). Though, let's not get excited, `SearchEngine` is part of the `analysis_server` package and it is not intended to be used as a package (i.e. not published on `pubspec.yaml`). The `analysis_server` as the name implies is meant to be used as a server. 

    Now we know that there's a solution. We can spin an analysis server, and do the following:

        1- send a request to find all top level declarations within a dart project.
        2- send a request to find references to all of the top level declarations that were found. 
        3- check if references are found to see whether or not the top level declaration is used. 


### How to communicate with the analysis server
Spinning an analysis server is simply done as follow:

```
dart language-server
```

But how do we communicate with the server now? :/

First let's take a step back and learn about the available protocols for communicating with the server. There are namely two protocols:

- [Dart Analysis Server (DAS) Protocol API](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html)
    
    This protocol is specific to Dart and I believe it's the one used by `DevTools` for the analysis part and it was used by the VS Code extension for Dart and Flutter. 
    
    > sometimes the DAS protocol is refered to as `legacy` protocol but I'm not sure if this has any indication that it'll be deprecated.

    The following command is used for running the language-server with DAS protocol:
    ```
    dart language-server --protocol=analyzer
    ```

- [Language Server Portocol (LSP) for Dart](https://github.com/dart-lang/sdk/tree/master/pkg/analysis_server/tool/lsp_spec)

    The [LSP protocol (main)](https://microsoft.github.io/language-server-protocol/) is: 
    > The Language Server Protocol is an open, JSON-RPC-based protocol for use between source code editors or integrated development environments and servers that provide programming language-specific features. 
    > source: https://en.wikipedia.org/wiki/Language_Server_Protocol

    This is the one used currently by the VS Code extension for Dart and Flutter which can be seen at [Dart-Code/Dart-Code](https://github.com/Dart-Code/Dart-Code/) 
    
    > note: if you look at the extension code, you'll find implementation for both DAS and LSP since the LSP was implemented later on from what I understood. 

    The following command is used for running the language-server with LSP protocol (default):
    ```
    dart language-server --protocol=lsp 
    ```
    
    For more details: 
    ```
    dart language-server --help
    ```


> Side Note:
> The [`analysis_server_client`](https://github.com/dart-lang/sdk/blob/edbf6300a13095e164a876ee33251ec91fea072f/pkg/analysis_server_client/lib/server.dart#L113) runs the analysis server using a snapshot that's typically located at `/path/to/dart-sdk/bin/snapshots/analysis_server.dart.snapshot`. So one can also run the server from the available snapshots in `dart-sdk` path such as:
> ```
> dart /path/to/dart-sdk/bin/snapshots/analysis_server.dart.snapshot --help
> ```
> In this case, DAS is default. 
> I assume `language-server` is a new command because it doesn't show up when running `dart --help` 


Back to the server communication. When running the server through (typically using `Process.run` in Dart), the communication is carried out using `stdio`. To facilitate the communication, we need a way to parse messages from stdout and errors from stderr, and build requests to be sent through stdin based on the used protocol. 

The `analysis_server` package already generates code for protocol constants which can be found [here for DAS](https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server/lib/protocol) and [here for LSP](https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server/lib/lsp_protocol). That still does not help since `analysis_server` cannot be used as a package. The good news is that the `analysis_server_client` package already contains the generated protocol (for `DAS` only) which is exported by the pacakge in this file: [lib/protocol.dart](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_client/lib/protocol.dart) to be utilized by the package users. 

> Note: the `analysis_server_client` does not have `LSP` implementation. This means, if one wants to use LSP, without generating the protocol constants themselves, they need to extract that from the `analysis_server` somehow (see how Dart-Code extension does it -- there's a script somewhere does that). Though for our goals here, `DAS` does what we need. 


In short, we will use `analysis_server_client` to communicate with the language server. The `analysis_server_client` already have a great example that can be found here: [analysis_server_client/example/example.dart](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_client/example/example.dart). The example shows how to set the analysis root (i.e. directory to be analyzed), listen to errors, send requests, and so on. 

If you're curious how the `stdio` communication are being handled, look at [analysis_server_client/lib/server.dart](https://github.com/dart-lang/sdk/blob/edbf6300a13095e164a876ee33251ec91fea072f/pkg/analysis_server_client/lib/server.dart#L54). This is helpful if you'd like to implement your own client server in case you want to do things differently.  

---

## Notes about working with the server:

- When sending requests to the server, `Server.send` will create a unique id for that request. 
- The server will acknowldege the request by returning a response containing that id. 
- Depending on the type of the request, the result may come back immediately, or come back later at once or at multiple times.

- here is an example:

    - Assume you already have a server instance that was started properly (subsription and analysis root were set). 
    - Send a request:
        ```dart
        final params = SearchFindTopLevelDeclarationsParams('.').toJson(); // this will search all since the input here is regex. 
        final response = await server.send(SEARCH_REQUEST_FIND_TOP_LEVEL_DECLARATIONS, params);
        ```
    - The response above will be (if this is the only request):
        ```
        {id: 0} 
        ```
    - Now in the results will come back through the `NotificationHandler` implementation:

    ```dart
    @override
    void onSearchResults(SearchResultsParams params) {
        if (params.isLast) {
        /* handle the last search result for the param.id = 0 and do not expect more */
        } else {
        /* handle the search result for the param.id = 0 and expect more to come */
        }
    }
    ```

It's worth noting that the [protocol document](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findTopLevelDeclarations) already defines the type of response and whether it's an immediate response or a delayed response.  



For a full example for how `finding top level declaration` using `analysis_server_client` is used, check out:
 - [Dart Flutter Scripts Repo](https://github.com/osaxma/dfs)
 - The client code is located here: [client.dart](https://github.com/osaxma/dfs/blob/main/lib/src/analysis_server/client.dart)
 - How it is used located here: [find_unused_top_level.dart](https://github.com/osaxma/dfs/blob/main/lib/src/find_unused_top_level/find_unused_top_level.dart).


--- 

## Some Known Limitations with the Anaylsis Server:

- The analysis server doesn't seem to have an explicit way to stop analyzing errors. 

    The server automatically ignores whatever is defined in `analysis_options.yaml`[analyzer][exclude] and `dot` folders (e.g. `.vscode`) (see the protocol because there could be more exclusions). In the use case we are only interested in sending requests to the server and we don't care about errors in the code, it would be logical to turn off the analysis errors since they can slow things down (IIRC, the `analysis_server_client` or its example, handles requests only after error analysis are done). 

    To workaround this issue, we start the subsription as follow:
    ```dart
    Future<void> _startSubscription() async {
        await server.send(
            SERVER_REQUEST_SET_SUBSCRIPTIONS, ServerSetSubscriptionsParams([ServerService.STATUS]).toJson(),
        );

        await server.send(
            ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
            AnalysisSetAnalysisRootsParams(
            [targetDir], // included: this seems the only to specify the root directory?
            [targetDir], // excluded: we are not interested in analysis errors so exclude all files from being analyzed.
            ).toJson(),
        );
    }
    ```
    The approach above was tested and it works. No errors are reported even if they exist and requests are handled for excluded files. 


- [search.findTopLevelDeclarations](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findTopLevelDeclarations) searches the entire project and its packages (seen results coming from `~/.pub_cache). Need to find if there's a way to scope the search to the root directory. 

    The following was a discussion from [Dart-Code Discord server](https://discord.com/channels/615553440969392147/697786943114838067/927221624338538566):

    **Question by @osaxma:**

    I've a question about Dart Analysis Server if you don't mind me asking here.. I've been tinkering with it for the past week and there was a lot to digest. In short, I'm creating a cli that uses `analysis_server_client` to find unused-top-level-declarations within a project and some other similar analysis. 

    I was able to get it work by simply using `search.findTopLevelDeclarations` then looping through the result by using  `search.findElementReferences` to find if the declaration has a reference. 

    Though, I noticed that [`search.findTopLevelDeclarations`](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_search.findTopLevelDeclarations) is not only searching the target directory specified in [`analysis.setAnalysisRoots`](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html#request_analysis.setAnalysisRoots) but it was returning results from all packages used within the project. I was able to filter them out by excluding any result where the root path isn't the same as the project root path the target directory. But I feel that the server is doing a lot of unnecessary work by searching everything. 

    My question is: Is there any way to scope the `search.findTopLevelDeclarations` to a specific directory and prevent searching all packages?

    This is how I'm starting the subscription:
    ```dart
    Future<void> _startSubscription() async {
        await server.send(
        SERVER_REQUEST_SET_SUBSCRIPTIONS,
        ServerSetSubscriptionsParams([ServerService.STATUS]).toJson(),
        );

        await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        AnalysisSetAnalysisRootsParams(
            [targetDir], // included: this seems the only to specify the root directory?
            [targetDir], // excluded: we are not interested in analysis errors so exclude all files from being analyzed.
        ).toJson(),
        );
    }
    ```
    where `targetDir` is the path to the project root folder. I tried scoping that to `lib` folder but I still get results from paths like `/Users/osaxma/.pub-cache/hosted/pub.dartlang.org/<package_name>`.


    **Answer from @DanTup:**
    I don't know of a way. It used to only do the analysis roots, but there was an issue raised saying this prevented jumping to a class in the SDK (for ex. StatefulWidget) so it was updated to support them all

    FWIW there's a group at https://groups.google.com/a/dartlang.org/forum/#!forum/analyzer-discuss that is monitored by analyzer devs much more knowledgeable than I, so if you're looking for the best way to do something that might be the place to get the best answers. My knowledge of the server internals is still fairly narrow (although I'm ofc happy to help where I can!)



---

## Extra: 

If you like to see how the `analysis_server` works, here's the good entry point: [`Driver.start`](https://github.com/dart-lang/sdk/blob/edbf6300a13095e164a876ee33251ec91fea072f/pkg/analysis_server/lib/src/server/driver.dart#L138) -- just dig deep from there to find how everything is started and used. And if you get lost, just go back to `Driver.start` and re-dive. You'll find yourself jumping into `analyzer` package quite often since many interfaces are defined there. The codebase is large, and it seems to have its own implementation of various components that could be standalone packages. I found it interesting.  
