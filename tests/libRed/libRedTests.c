//
//  Run Red tests via libRed
//
//  Created by Peter W A Wood on 27/03/2017.
//  Copyright © 2017 Peter W A Wood. All rights reserved.
//  BSD-3 License see https://github.com/red/red/blob/origin/BSD-3-License.txt
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../libRed/red.h"

int main(int argc, const char *argv[]) {
    char line[230];
    FILE *test_list;
    char test_path[255];
    
    test_list = fopen("../source/units/all-tests.txt", "r");
    if (test_list == NULL) {
      fprintf(stderr, "***Test Aborted*** : unable to find 'all-tests.txt' file\n");
      exit(1);
    };
    
    redOpen();
    redDoFile("../../quick-test/quick-test.red");
    redDo("***start-run*** {libRed}");
    
    while (fgets(line, sizeof(line), test_list)) {
      if (line[1] != ';') {
        strcpy(test_path, "../source/units/");
        strncat(test_path, line, strlen(line) - 1);        //Remove #"^(0A)"
        redDoFile(test_path);
      }
    } 
    
    redDo("***end-run***");
    redClose();
    return(0);
}
