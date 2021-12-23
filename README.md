# DFS - Dart Flutter Scripts (warning everything is still WIP)

A collection of useful scripts for dart or flutter projects. 

The scripts can be executed in the working directory of any dart or flutter project. 

## Installation:

Until the package is published to `pub.dev`, it can be installed as follow:
```
[~] dart pub global activate --source git https://github.com/osaxma/dfs.git
```

To run any script:
```
[~/path/to/project] dfs <script-command>
```

> Note: each script will only work in the current working directory (i.e. one cannot pass a path to a different directory -- *at least for now*).

Each `<script-command>` is shown below under the available scripts.  

## Available Scripts 

<!-- TODO: move each scripts details in a different readme and keep it simple here -->
<!-- TODO: Make each script a stand-alone package within the project so it's useable elsewhere? -->

- **Find Unused Packages** *(status: MVP is working)* <br>
    >**Area:** project hygien<br>
    **command**: ```find-unused-packages``` <br>
    **alias:** `fup`

   **Description:**<br>
    with the help of dart's `analyzer` and `pubspec` packages, the script inpset both the `pubspec.yaml` file and all dart files within `lib` to find any unused dependencies. 

   **Sample Output:**
    ```log
    [~/cwd] dfs find-unused-packages
        The following packages are not used anywhere in the lib directory. If they are used
        elsewhere (e.g. /test), consider moving them to `dev_dependencies` in `pubspec.yaml`
            - code_builder
            - dart_style
            - logging
    ```
    
    <!-- TODO: 
        - find unused `dependencies` across the project (now we only check lib).
        - find unused `dev_dependencies` across the project.  -->
    
    Use case: keep the project clean and avoid confusing myself.


- **Find Unused Top Level Declaration** *(status: MVP)*<br>
    >**Area**: project hygiene<br>
    **command**: `find-unused-top-level` <br>
    **alias:** `futl`
    
    Finds unused top-level elements (classes, typedefs, getters, setters, functions and fields). This useful for dart/flutter projects that are not packages. 


## WIP Scripts
- **Generate Data Classes** *(status: WIP)*<br>
    >**Area**: utility<br>
    **command**: `generate-data-classes` <br>
    **alias:** `gdc`

    Use case: I don't like magically generated undebuggable code. I currently use `Dart Data Class Generator` extension in VS code which modifies the code in place to generate the following:
    - `copyWith` method.
    - serialization methods (`toMap`/`toJson`) and desirialization factories (`fromMap`/`fromJson`). 
    - Equality (`operator ==`) and `hashcode`. 

    Generated code looks clean and tidy but the extension does few things different than I like (e.g. handling default values and some other minor details). 




## Ideas for future scripts
- **Find Unused Widgets** *(status: TBD)*<br>
    >**Area**: project hygiene<br>
    **command**: TBD <br>
    **alias:** TBD
    <!-- Find out how `find all references` is invoked at the language server -- maybe spin up the server to utilize it -->
    The idea is to find unused widgets within a project. This cannot be used with packages where since widgets could be in use outside the project. 

    Use case: I always have to comment a widget out to see if it's used elsewhere in the project (i.e. I wait for files to go red).

- **Find All Unused** *(status: TBD)*<br>
    >**Area**: project hygiene<br>
    **command**: TBD <br>
    **alias:** TBD
    <!-- Find out how `find all references` is invoked at the language server -- maybe spin up the server to utilize it -->
    <!-- or make this a report generator about the project/package/etc. -->
    <!-- a lot of ideas can be done here -- dependency graph between files/folders/packages, API surface measure, code coverage, etc. -->
    <!-- for dependency graph, see: https://pub.dev/packages/lakos and also see https://pub.dev/packages/directed_graph -->
    Run all the other scripts to find unused packages, widgets, top level declarations, etc. 

- **Change Project Name** *(status: TBD)*<br>
    >**Area**: pain<br>
    **command**: TBD <br>
    **alias:** TBD
    <!-- This may should take the flutter version into account -->
    This is mainly for Flutter, and especially for multiplatform code where the name has to be changed in various places. 




<!-- ----------------------------------------------------------------------- -->
<!--                                  IDEAS                                  -->
<!-- ----------------------------------------------------------------------- -->

<!-- 
- **Run Script** *(status: TBD)*<br>
    >**Area**: utility<br>
    **command**: run <br>
    **alias:** N/A
    ```
    [~/cwd] dfs run <script> 
    ```
    Where <script> is defined in `pubspec.yaml` 
    ```yaml
        script:
            build: flutter pub run build_runner build --delete-conflicting-outputs
        data:
            dfs generate-data-classes --endsWith="_data.dart" --directory="lib"
    ```

    This is similar to `derry` package but it doesn't look like that it has been maintained for a while
-->


<!-- 
- **Get Packages For All** *(status: TBD)*<br>
    >**Area**: utility<br>
    **command**: TBD <br>
    **alias:** TBD 

    ```
    [~/cwd] dfs get packages --all
    ```
    Or 
    ```
    [~/cwd] dfs get all
    ``` 

For monorepo or a repo with multiple packages. 

Use case: This was a pain when cloning a monorepo. I had this issue when I cloned `gql` which has a dozen of pacakges within the same repo. 

The script should find all `pubspec.yaml` files recursively in the cwd. 

-->


<!-- ----------------------------------------------------------------------- -->
<!--                                  NOTES                                  -->
<!-- ----------------------------------------------------------------------- -->


<!-- 
TODO: add motivation section:
While There are many packages/executable that do one simple thing (which is great), there are some downsides:
        - one has to install all of them
        - learn all of their quirks 
        - get lost when the package is no longer maintained.
I believe having a single package that provide utility scripts for dart/flutter developer is a valid use case and hopefully the community will participate to grow this project...  
 -->





<!-- ----------------------------------------------------------------------- -->
<!--                        Notes on Analysis Server                         -->
<!-- ----------------------------------------------------------------------- -->

<!-- 
Problem we are trying to solve:
- Given a field declaration reference at hand (i.e. from an AST), how can we find all the refrences for it within a project?

Discovery:
It looks like the [SearchEngine](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/lib/src/services/search/search_engine.dart#L43) from `analysis_server` package is the answer. Though the search engine cannot work on its own. It has to work with other parts such as [AnalysisDriver], [AnalysisSession], [ResourceProvider], etc. from the `analyzer` package (see: [AbstractAnalysisServer] constructor from `analysis_server` package). In short, it's too much to set up and manage.

The easiest way sems to be Spinning up an `analysis_server` and communicate with it. This may seem like an over kill for such task, but it's much better than reinventing the wheels. 

Note: the analysis server doesn't seem to have a way to stop analyzing errors (at least in Dart Server Protocol). The server automatically ignores whatever is defined in `analysis_options.yaml`[analyzer][exclude] and `dot` folder (e.g. `.vscode`) (see the protocol if there are more). Since we are only interested in sending query for a given field in a given project directory, it would be logical to turn off errro analysis. Maybe excluding the entire project is the easiest option (as long as the server doesn't read analysis_options on its own then we're stuck). In Dart Analysis Server, the excluded files can be explicitly defined. 

Protocols:
There are two protocols:
    - [Dart Analysis Server Protocol](https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html)

    - [Language Server Protocol](https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/tool/lsp_spec/README.md)

The `analysis_server` package understands both. Tho `analysis_server_client` only works with the first one. It seems like LSP is easier to work with since that's what IDEs use. 

```
[~] cd ~/playground/sdk/pkg/analysis_server/                # <~~ local copy of sdk
[~/playground/sdk/pkg/analysis_server/] dart run bin/server.dart --help
Usage: analysis_server [flags]

Supported flags are:
-h, --help                                Print this usage information.
    --client-id=<name>                    An identifier for the analysis server client.
    --client-version=<version>            The version of the analysis server client.
    --dart-sdk=<path>                     Override the Dart SDK to use for analysis.
    --cache=<path>                        Override the location of the analysis server's cache.
    --packages=<path>                     The path to the package resolution configuration file, which supplies a mapping of package names
                                          into paths.
    --protocol=<protocol>                 Specify the protocol to use to communicate with the analysis server.

          [analyzer] (default)            Dart's analysis server protocol (https://dart.dev/go/analysis-server-protocol)
          [lsp]                           The Language Server Protocol (https://microsoft.github.io/language-server-protocol)

Server diagnostics:
    --protocol-traffic-log=<file path>    Write server protocol traffic to the given file.
    --analysis-driver-log=<file path>     Write analysis driver diagnostic data to the given file.
    --diagnostic-port=<port>              Serve a web UI for status and performance data on the given port.
```


 -->

