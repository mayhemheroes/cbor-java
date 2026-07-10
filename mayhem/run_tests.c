#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef MVN
#define MVN "/opt/toolchains/maven/bin/mvn"
#endif

int main(int argc, char **argv) {
    int pipefd[2];
    if (pipe(pipefd) != 0) {
        perror("pipe");
        return 1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);

        char **a = (char **)calloc((size_t)argc + 8, sizeof(char *));
        if (!a) {
            _exit(1);
        }
        int n = 0;
        a[n++] = (char *)MVN;
        a[n++] = (char *)"-B";
        a[n++] = (char *)"-Dmaven.repo.local=/opt/toolchains/maven-repo";
        a[n++] = (char *)"-Dgpg.skip=true";
        a[n++] = (char *)"-Djavac.src.version=11";
        a[n++] = (char *)"-Djavac.target.version=11";
        a[n++] = (char *)"-Djacoco.skip=true";
        a[n++] = (char *)"surefire:test";
        for (int i = 1; i < argc; i++) {
            a[n++] = argv[i];
        }
        a[n] = NULL;
        execvp(MVN, a);
        _exit(127);
    }

    close(pipefd[1]);
    FILE *fp = fdopen(pipefd[0], "r");
    if (!fp) {
        perror("fdopen");
        return 1;
    }

    char line[4096];
    int tests = -1, failures = -1, errors = -1, skipped = -1;
    while (fgets(line, sizeof(line), fp)) {
        fputs(line, stdout);
        if (strstr(line, "Tests run:") != NULL) {
            char *p = strstr(line, "Tests run:");
            sscanf(p, "Tests run: %d, Failures: %d, Errors: %d, Skipped: %d",
                   &tests, &failures, &errors, &skipped);
        }
    }
    fclose(fp);

    int status = 0;
    waitpid(pid, &status, 0);
    int rc = WIFEXITED(status) ? WEXITSTATUS(status) : 1;

    if (tests >= 0) {
        int failed = failures + errors;
        int passed = tests - failed - (skipped >= 0 ? skipped : 0);
        printf("RUNTESTS tests=%d passed=%d failed=%d errors=%d skipped=%d rc=%d\n",
               tests, passed, failed, errors, skipped >= 0 ? skipped : 0, rc);
    }

    return rc;
}
