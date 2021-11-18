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

    // FIXME: may not be necessary
    function addClass(node, cs) {
        for (const c of cs.split(' ')) {
            node.classList.add(c);
        }
    }

    function updateSelection(node, event) {
        const tgt = event.target;
        const cards = node.querySelectorAll("[data-type='card']");
        const adds = node.querySelectorAll("[data-type='add']");
        let addsClicked = false;

        for (let add of adds) {
            if (add.contains(tgt)) {
                add.dataset.selected = "true";
                addsClicked = true;
            } else {
                add.dataset.selected = "false";
            }
        }
        for (let card of cards) {
            if (card.contains(tgt)) {
                card.dataset.selected = "true";
                card.classList.add("border-blue-800");
                card.classList.remove("border-transparent");
            } else if (!addsClicked) {
                card.dataset.selected = "false";
                card.classList.add("border-transparent");
                card.classList.remove("border-blue-800");
            }
        }
    }

    return {
        cycle,
        styleSelected,
        readFiles,
        addClass,
        updateSelection,
    }
})();