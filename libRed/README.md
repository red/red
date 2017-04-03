### Generating .LIB file for Windows platform

* Using Visual Studio Tools

  Open the Visual Studio Command Prompt, in `Start->Programs->Microsoft Visual Studio->Tools`, run this command:

  ```
  lib /def:<path_to_red_repo>\libRed\libRed.def /OUT:<path_to_red_repo>\libRed\libRed.lib /MACHINE:X86
  ```

  That’s all. :-)