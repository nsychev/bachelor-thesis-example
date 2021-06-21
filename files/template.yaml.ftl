version: '0.1'
phases:
    first-run-${test.sequenceId}:
        images:
            - compiler: true
        input:
            - type: temp-file
              from:
                  phase: compile
                  output: 1
            - type: pipe
              from:
                  phase: first-judge-${test.sequenceId}
                  output: 1
        output:
            - type: pipe
        on-fail:
            action: skip
            phases:
              - second-run-${test.sequenceId}
              - second-judge-${test.sequenceId}
              - check
        command: |
            run $1 < $2 > $3
        limits:
            cpu-time: 3000
            real-time: 6000
            memory: 1073741824
    first-judge-${test.sequenceId}:
        images:
            - custom: compilers/base
        input:
            - type: problem-file
              name: files/interact
            - type: pipe
              from:
                  phase: first-run-${test.sequenceId}
                  output: 1
            - type: problem-file
              name: ${test.inputPath}
            - type: problem-file
              name: ${test.answerPath}
        output:
            - type: pipe
            - type: temp-file
        command: |
            # interactor input output answer < pipe > pipe
            $1 $3 $6 $4 < $2 > $5
        on-fail:
            action: skip
            phases:
              - second-run-${test.sequenceId}
              - second-judge-${test.sequenceId}
              - check
    second-run-${test.sequenceId}:
        images:
            - compiler: true
        input:
            - type: temp-file
              from:
                  phase: compile
                  output: 1
            - type: pipe
              from:
                  phase: second-judge-${test.sequenceId}
                  output: 1
        output:
            - type: pipe
        on-fail:
            action: ignore
        command: |
            run $1 < $2 > $3
        limits:
            cpu-time: 3000
            real-time: 6000
            memory: 1073741824
        on-fail:
            action: skip
            phases:
              - check
    second-judge-${test.sequenceId}:
        images:
            - custom: compilers/base
        input:
            - type: problem-file
              name: files/interact
            - type: pipe
              from:
                  phase: second-run-${test.sequenceId}
                  output: 1
            - type: temp-file
              from:
                  phase: first-judge-${test.sequenceId}
                  output: 2
            - type: problem-file
              name: ${test.answerFile}
        output:
            - type: pipe
            - type: temp-file
        command: |
            # interactor input output answer < pipe > pipe
            $1 $3 $6 $4 < $2 > $5
        on-fail:
            action: skip
            phases:
              - check
    check:
        images:
            - custom: compilers/base
        input:
            - type: problem-file
              name: files/check
            - type: temp-file
              from:
                  phase: second-judge-${test.sequenceId}
                  output: 2
            - type: problem-file
              name: ${test.inputPath}
            - type: problem-file
              name: ${test.answerPath}
        command: |
            $1 $3 $2 $4
        on-fail:
            action: ignore
