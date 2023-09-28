# 2023-Sept

This tool has been superceeded by:

- [```codeIssues```](https://www.mathworks.com/help/matlab/ref/codeissues.html?s_tid=mwa_osa_a) released with MATLAB R2022b.
- [Jenkin's Warnings-NG](https://www.jenkins.io/doc/pipeline/steps/warnings-ng/) plugin.

# matlab_mflakes
pyflakes for matlab.
   
## Jenkins 

Requires [Warnings](https://plugins.jenkins.io/warnings).

Define a new parser at http://[jenkins-url]/configure and create a new parser in section Compiler Warnings.

### Regex

```
^([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|
```

### Mapping Script

```
import hudson.plugins.warnings.parser.Warning
import hudson.plugins.analysis.util.model.Priority

String fileName = matcher.group(1)
Integer lineNumber = Integer.parseInt(matcher.group(2))
String type =  matcher.group(3)
String category = matcher.group(4)
String message = matcher.group(5)
String severity = matcher.group(6)

Priority priority = Priority.NORMAL

switch (severity) {
    case "H":
        priority = Priority.HIGH
        break
    case "N":
        priority = Priority.NORMAL
        break
    case "L":
        priority = Priority.LOW
        break
    default:
        priority = Priority.NORMAL
}

return new Warning(fileName, lineNumber, type, category, message, priority)
```
