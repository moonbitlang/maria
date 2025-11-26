# internal/path 

## Design Principles

There are two main design principles for handling failed cases, 
in order to improve log experience and developer experience, 
for every path operation raise error is not very good behavior,
user might always panic for some obvious and trivial cases.

Those principles is predictive, easy to use, but not robust because which API doesn't enforce user to handle failed cases explicitly.

1. for path sub-structure extraction when operation fails, return empty string is reasonable.
2. for path sub-structure modification when operation fails, return original path is reasonable.


The most of path API in other language always provide the default behavior for non trivial cases.

1. Python `os.path.join`, Node.js `path.resolve` ignore the previous path when meet abosolute path. 
2. Node.js API when meet empty string sometimes return `.`, but some API return empty string, although it behavior is reasonable, but not consistent and predictive.

anti-patterns

```JavaScript 
// return `.` is not predictive for newbie
> const path = require("node:path")
undefined
> path.join("","")
'.'
> path.dirname("")
'.'
> path.basename("")
''
```

## other design decision

If API user expect handle all failed cases and edge cases explicitly, which user could write a new path library raise error. If user always ignore error then re-raise error automatically, but this developer experience is not good.

maria is LLM code agent, so LLM could self-justify to solve some edge cases, report issues to end user.if LLM tools can't generate correct path, just return original path, LLM could report more end user friendly message.