const utilities = (function () {

    // javascript `Math.mod` can be negative
    function mod(n, d) {
        return ((n % d) + d) % d;
    }

    function cycle(value, len, offset) {
        // take into account 0-based indexing when cycling from `null`
        const nextValue = (value === null && offset > 0) ? offset - 1 : value + offset;
        return mod(nextValue, len);
    }

    function styleSelected(nodes, idx, activeClasses, inactiveClasses) {
        for (let i = 0; i < nodes.length; i++) {
            const child = nodes[i];
            if (i == idx) {
                child.classList.add(...activeClasses);
                child.classList.remove(...inactiveClasses);
            } else {
                child.classList.remove(...activeClasses);
                child.classList.add(...inactiveClasses);
            }
        }
    }

    function readFiles(files, sink) {
        const nFiles = files.length;
        const fileDict = {};
        let waiting = true;
        for (let n = 0; n < nFiles; n++) {
            const file = files[n];
            const fileReader = new FileReader();
            fileReader.onload = function () {
                fileDict[n] = fileReader.result;
                if (waiting && Object.keys(fileDict).length == nFiles) {
                    waiting = false;
                    JSServe.update_obs(sink, fileDict);
                }
            };
            fileReader.onerror = function () {
                alert(fileReader.error);
            };
            fileReader.readAsText(file);
        }
    }

    function addClass(node, cs) {
        for (const c of cs.split(' ')) {
            node.classList.add(c);
        }
    }

    return {
        cycle: cycle,
        styleSelected: styleSelected,
        readFiles: readFiles,
        addClass: addClass,
    }
})();