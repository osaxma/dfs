# DFS - Dart Flutter Scripts 

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

- **Find Unused Widgets** *(status: TBD)*<br>
    >**Area**: project hygiene<br>
    **command**: TBD <br>
    **alias:** TBD

    The idea is to find unused widgets within a project. This cannot be used with packages where since widgets could be in use outside the project. 

    Use case: I always have to comment a widget out to see if it's used elsewhere in the project (i.e. I wait for files to go red).


- **Find Unused Top Level Declaration** *(status: TBD)*<br>
    >**Area**: project hygiene<br>
    **command**: TBD <br>
    **alias:** TBD

    The idea is to find unused top level functions or global variables within a project. This cannot be used with packages since such definitions could be in use outside the project. 

    Use case: I always have to comment a functions/variables out to see if they're used elsewhere in the project (i.e. I wait for files to go red).

- **Find All Unused** *(status: TBD)*<br>
    >**Area**: project hygiene<br>
    **command**: TBD <br>
    **alias:** TBD

    Run all the other scripts to find unused packages, widgets, top level declarations, etc. 


- **Generate Data Classes** *(status: WIP)*<br>
    >**Area**: utility<br>
    **command**: `generate-data-classes` <br>
    **alias:** `gdc`

    Use case: I don't like magically generated undebuggable code. I currently use `Dart Data Class Generator` extension in VS code which modifies the code in place to generate the following:
    - `copyWith` method.
    - serialization methods (`toMap`/`toJson`) and desirialization factories (`fromMap`/`fromJson`). 
    - Equality (`operator ==`) and `hashcode`. 

    Generated code looks clean and tidy but the extension does few things different than I like (e.g. handling default values and some other minor details). 

## Installation

TBD

