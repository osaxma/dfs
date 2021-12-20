# DFS - Dart Flutter Scripts 

A collection of useful scripts for dart or flutter projects. 

The scripts can be executed in the working directory of any dart or flutter project. 

## Installation:

```
TBD
```

## Available Scripts 

<!-- TODO: move each scripts details in a different readme and keep it simple here -->
<!-- TODO: Make each script a stand-alone package within the project so it's useable elsewhere? -->

- **Find Unused Packages** *(status: MVP is working)* <br>
    *Area: project hygiene*

   >**Description:**<br>
    with the help of dart's `analyzer` and `pubspec` packages, the script inpset both the `pubspec.yaml` file and all dart files within `lib` to find any unused dependencies. 

    **Usage:**

    ```sh
    [path/to/project/directory] dfs find-unused-packages 
    ```
   **Output:**
    ```log
    The following packages are not used anywhere in the lib directory. If they are used
    elsewhere (e.g. /test), consider moving them to `dev_dependencies` in `pubspec.yaml`
        - code_builder
        - dart_style
        - logging
    ```
    
    <!-- TODO: 
        - find unused `dependencies` across the project (now we only check lib).
        - find unused `dev_dependencies` across the project.  -->

- **Find Unused Widgets** *(status: TBD)*<br>
    *Area: project hygiene*

    The idea is to find unused widgets within a project. This cannot be used with packages where since widgets could be in use outside the project. 


- **Find Unused Top Level Declaration** *(status: TBD)*<br>
    *Area: project hygiene*

    The idea is to find unused top level functions or global variables within a project. This cannot be used with packages since such definitions could be in use outside the project. 


- **Generate Data Classes** *(status: WIP)*<br>
    *Area: utility*

## Installation

TBD

