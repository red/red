//
//  main.c
//  test
//
//  Created by Peter W A Wood on 28/03/2017.
//  Copyright © 2017 Peter W A Wood. All rights reserved.
//  BSD-3 License see https://github.com/red/red/blob/origin/BSD-3-License.txt
//


#include "../../libRed/red.h"

int main(int argc, const char *argv[]) {
    
    redOpen();
    redDoFile("../../quick-test/quick-test.red");
    redDoFile(argv[1]);
    redClose();
    return(0);
    
}
