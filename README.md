# DFS - Dart Flutter Scripts 
> Warning: everything is WIP.

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

# Available Scripts 

<!-- TODO: move each scripts details in a different readme and keep it simple here -->
<!-- TODO: Make each script a stand-alone package within the project so it's useable elsewhere? -->

- **Find Unused Packages** *(status: MVP)* <br>
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

    ---
- **Find Unused Top Level Declaration** *(status: MVP)*<br>
    >**Area**: project hygiene<br>
    **command**: `find-unused-top-level` <br>
    **alias:** `futl`
    
    Finds unused top-level elements (classes, typedefs, getters, setters, functions and fields). This useful for dart/flutter projects that are not packages. 
    
    **Sample output**
    ```sh
    [~/cwd]$ dart run bin/dfs.dart futl
        finding unused top level declarations...  
        The following top level declarations are not used anywhere 
            - /cwd/lib/src/version.dart:7:7
            - /cwd/lib/src/common/ast_utils.dart:7:9
    ```
     ---
- **Generate Data Classes** *(status: MVP)*<br>
    >**Area**: utility<br>
    **command**: `generate-data-classes` <br>
    **alias:** `gdc`

    Generate the following for an existing class (in place):
    - `copyWith` method.
    - serialization methods (`toMap`/`toJson`) and desirialization factories (`fromMap`/`fromJson`). 
    - Equality (`operator ==`) and `hashcode`. <br><br>

    See how the data looks like before and after running the script at:
    - [before running the script](samples/data_class_samples/input_example_data.dart)
    - [after running the script](samples/data_class_samples/output_data_example.dart)
    
    <br> 

    The input data is read by parsing the Abstract Syntax Tree (AST) using the [`analyzer package`](https://github.com/dart-lang/sdk/tree/main/pkg/analyzer), and then the data class is built using the [`code builder package`](https://github.com/dart-lang/code_builder). 


# Ideas for future scripts
- **Change Project Name** *(status: TBD)*<br>
    >**Area**: pain<br>
    **command**: TBD <br>
    **alias:** TBD
    <!-- This may should take the flutter version into account -->
    This is mainly for Flutter, and especially for multiplatform code where the name has to be changed in various places. 

    ---
- **Run Script** *(status: TBD)*<br>
    >**Area**: utility<br>
    **command**: run <br>
    **alias:** N/A
    ```
    [~/cwd] dfs run <script> 
    ```
    Where \<script> is defined in `pubspec.yaml` 
    ```yaml
        script:
            build: flutter pub run build_runner build --delete-conflicting-outputs
            data: dfs generate-data-classes --endsWith="_data.dart" --directory="lib"
    ```
    ---

- **Get Packages For All** *(status: TBD)*<br>
    >**Area**: utility<br>
    **command**: TBD <br>
    **alias:** TBD 
    <!-- The script should find all `pubspec.yaml` files recursively in the cwd.  -->

    ```
    [~/cwd] dfs get packages --all
    ```
    Or 
    ```
    [~/cwd] dfs get all
    ``` 

    Run `dart pub get` or `flutter packages get` for all packages within a monorepo or a repo with multiple packages.




<!-- ----------------------------------------------------------------------- -->
<!--                                  IDEAS                                  -->
<!-- ----------------------------------------------------------------------- -->

<!-- 
 **Generate Analytical Report** *(status: TBD)*<br>
    >**Area**: utility<br>
    **command**: TBD <br>
    **alias:** TBD
     a lot of ideas can be done here -- 
     
    - Run all the other scripts to find unused packages, top level declarations, etc. 
    - Generate dependency graph between files/folders/packages, API surface measure, code coverage, etc.
        - for dependency graph, see:
            https://pub.dev/packages/lakos 
            https://pub.dev/packages/directed_graph
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

Hopefully having a single package can help attract more users, and hence more contributors to keep the package sustinable. 
 -->
