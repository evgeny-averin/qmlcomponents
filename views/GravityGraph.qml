import QtQuick 2.3
import Physics 1.0
import "../common/utils.js" as Utils

Item {
    id: gravityGraph

    property real damping: 10.1
    property real density: 150
    property int  count: 0
    property string source: ""
    property int counter: 0
    property Item graphLoader: nullItem
    property Component delegate: null
    property real linkLength: 5

    signal loaded();

    function onRemoved()
    {
    }

    function isEmpty()
    {
        return flickable.contents().children.length === 0;
    }

    onSourceChanged: {
        load();
        flickable.contentX = flickable.contentY = 0;
    }

    Storage {
        id: storage
    }

    Timer {
        id: tmrSimulate
        running:  false
        repeat:   true
        interval: 8
        onTriggered: {
            world.simulate();
        }
    }

    Timer {
        id: tmrSimSingle
        running:  false
        repeat:   false
        interval: 33
        onTriggered: {
            world.simulate();
        }
    }

    Timer {
        id: tmrSimStop
        interval: 300
        repeat: false
        onTriggered: {
            tmrSimulate.stop();
            save();
        }
    }

    function doSimulate()
    {
        tmrSimulate.start();
        tmrSimStop.start();
    }


    onWidthChanged: {
        world.setScreenWidth(width);
    }

    onHeightChanged: {
        world.setScreenHeight(height);
    }

    Component.onCompleted: {
        world.screenMetric = 0.1;
    }

    function createNode(x, y, nodeID, metadata)
    {
        doSimulate();

        var ret = null;
        var node_id = nodeID ? nodeID : counter;

        if (!nodeID) {
            ++counter;
        }

        if (flickable.contents().children.length === 0) {
            ret = cmpNode.createObject(flickable.contents(), {
                nodeID: node_id,
                group: 1,
                position: Qt.point(x, y),
                metadata: metadata
            });
        } else {
            ret = cmpNode.createObject(flickable.contents(), {
                nodeID: node_id,
                group: 1,
                position: Qt.point(x, y),
                metadata: metadata
            });
        }

        return ret;
    }

    function createChild(item, params)
    {
        var pos = Qt.point(item.position.x, item.position.y);

        if(item.link) {
            var angle = item.link.rotation + (Math.random() - 0.5) * 30;
            pos.x -= 4 * Math.cos(Utils.to_rad(angle));
            pos.y += 4 * Math.sin(Utils.to_rad(angle));
        } else {
            angle = (Math.random() + 1.) * 360.;
            pos.x -= 4 * Math.cos(Utils.to_rad(angle));
            pos.y += 4 * Math.sin(Utils.to_rad(angle));
        }

        var new_item = createNode(pos.x, pos.y, undefined, params);
        createLink(item, new_item);
    }

    function removeNode(node)
    {
        if (!node.isRoot()) {
            node.destroy();
        }
    }

    function createLink(src, dst)
    {
        var link = cmpLink.createObject(flickable.contents(), {
            src: src,
            dst: dst,
        });

        src.addChildLink(link);
    }

    function saveDB()
    {
        var node_table = gravityGraph.source.split(".")[0] + "_nodes";
        var link_table = gravityGraph.source.split(".")[0] + "_links";

        storage.dropTable(node_table);
        storage.dropTable(link_table);

        console.log("save to table", node_table);

        storage.updateTable(node_table, function () {
            var entries = [];
            for (var i in flickable.contents().children) {
                var item = flickable.contents().children[i];
                if (item.isNode) {
                    var entry = item.serializeDB();
                    entry["NodeID"] = item.nodeID;
                    entries.push(entry);
                }
            }

            for (i = 0; i < entries.length; ++i) {
                entry = entries[i];
                console.log("entry", i);
                for (var key in entry) {
                    console.log("    ", key, entry[key]);
                }
            }

            return entries;
        });

        storage.updateTable(link_table, function () {
            var links = [];
            for (var i in flickable.contents().children) {
                item = flickable.contents().children[i];
                if (item.isNode) {
                    for (var j in item.childLinks) {
                        var link = item.childLinks[j];
                        links.push({src: link.src.nodeID, dst: link.dst.nodeID})
                    }
                }
            }

            for (i = 0; i < links.length; ++i) {
                link = links[i];
                console.log("link", i);
                for (var key in link) {
                    console.log("    ", key, link[key]);
                }
            }

            return [];
        });
    }

    function save()
    {
        saveDB();


        var str = str = "import QtQuick 2.2\nItem {\n";
        var indent = "    ";
        str += indent + "property int counter: " + gravityGraph.counter + "\n";

        str += indent + "property var nodes: {\n";
        for (var i in flickable.contents().children) {
            var item = flickable.contents().children[i];
            if (item.isNode) {
                str += indent.concat(indent) + "\"" + item.nodeID + "\"" + ": { ";
                str += item.serialize();
                str += " },\n";
            }
        }
        str += indent + "}\n";

        str += indent + "property var links: [\n";
        for (i in flickable.contents().children) {
            item = flickable.contents().children[i];
            if (item.isNode) {
                for (var j in item.childLinks) {
                    var link = item.childLinks[j];
                    str += indent.concat(indent) + "{ src: " + link.src.nodeID + ", dst: " + link.dst.nodeID + "},\n"
                }
            }
        }
        str += indent + "]\n"

        str += "}";

        return fileIO.write(gravityGraph.source, str);
    }

    function saveEmpty()
    {
        var str = str = "import QtQuick 2.2\nItem {\n";
        str += "property int counter: 0\n";

        str += "property var nodes: {\n";
        str += "}\n";

        str += "property var links: [\n";
        str += "]\n"

        str += "}";

        console.log(str);
        return fileIO.write(gravityGraph.source, str);
    }

    function load()
    {
        if (graphLoader) {
            graphLoader.destroy();
            graphLoader = nullItem;
        }

        flickable.clearContents();

        var str = fileIO.readAll(source);
        console.debug("Loading GravityGraph from", source + ".");
        if (str.length > 0) {
            console.debug("File loaded successfully.", str)
            graphLoader = Qt.createQmlObject(str, gravityGraph);
            gravityGraph.counter = graphLoader.counter;

            var item_list = {};
            for (var i in graphLoader.nodes) {
                item_list[i] = gravityGraph.createNode(graphLoader.nodes[i].x, graphLoader.nodes[i].y, i, graphLoader.nodes[i].metadata);
            }

            for (i in graphLoader.links) {
                var src = item_list[graphLoader.links[i].src];
                var dst = item_list[graphLoader.links[i].dst];

                if (src && dst) {
                    gravityGraph.createLink(src, dst);
                }
            }
            gravityGraph.loaded();
        } else {
            console.debug("Failed loading, trying again.")
            if (saveEmpty()) {
                load();
            }
        }
    }

    Component {
        id: cmpJoint
        DistanceJoint {
            damping: 1
        }
    }

    Item {
        id: nullItem
    }

    Component {
        id: cmpNode
        Item {
            id: nodeItem
            property point size: Qt.point(2.5, 2.5)
            property alias type:     bodyItem.type
            property alias shape:    bodyItem.shape
            property alias group:    bodyItem.group
            property alias sensor:   bodyItem.sensor
            property alias position: bodyItem.position
            property var   body:     bodyItem
            property bool  isGraphNode: true
            property point center: Qt.point(x + width / 2, y + height / 2)
            property Item  parentLink: null
            property var   childLinks: []
            property int   nodeID: 0
            property Item  delegate: null
            property bool  isNode: true
            property var   metadata: ({})

            width: positioner.width
            height: positioner.height

            NumberAnimation on opacity {from: 0; to: 1; duration: 300}
            NumberAnimation on scale   {from: 0; to: 1; duration: 300}

            onMetadataChanged: {
                gravityGraph.save();
            }

            Component.onDestruction: {
                var parent_node = parentNode();

                if (parent_node) {
                    eachChild(function (child) {
                        child.setParentNode(parent_node);
                    });

                    parent_node.removeChildLink(this.parentLink);
                    this.parentLink.destroy();
                }
                gravityGraph.doSimulate();
            }

            onOpacityChanged: {
                if (parentLink) {
                    parentLink.opacity = opacity;
                }
            }

            function parentNode()
            {
                if (parentLink) {
                    return parentLink.src;
                }
                return null;
            }

            function setParentNode(another)
            {
                if (this.parentLink) {
                    this.parentLink.src = another;
                    another.addChildLink(this.parentLink);
                }
            }

            function isRoot()
            {
                return parentNode() === null;
            }

            function addChildLink(link)
            {
                if (childLinks.lastIndexOf(link) == -1) {
                    childLinks.push(link);

                    if(parentLink && childLinks.length > 1) {
                        parentLink.joint.length = Math.min(gravityGraph.linkLength * Math.max(childLinks.length, 1), gravityGraph.linkLength * 8);
                    }
                }
            }

            function removeChildLink(link)
            {
                var i = childLinks.lastIndexOf(link);
                if (i !== -1) {
                    childLinks.splice(i, 1);

                    for (i in gravityGraph.links) {
                        var link_pair = gravityGraph.links[i];
                        if (link_pair.src === link.src.nodeID && link_pair.dst === link.dst.nodeID) {
                            gravityGraph.links.splice(i, 1);
                            break;
                        }
                    }
                }
            }

            function eachChild(proc)
            {
                childLinks.forEach(function (link) {
                    proc(link.dst);
                });
            }

            function to_s()
            {
                return delegateLoader.item.to_s();
            }

            function serializeDB()
            {
                var data = {x: position.x, y: position.y};
                for (var key in metadata) {
                    data[key] = metadata[key];
                }

                return data;
            }

            function serialize()
            {
                var str = "x: " + position.x + ", y: " + position.y + ", metadata: {";

                for (var key in metadata) {
                    str += "" + key + ": \"" + metadata[key] + "\",";
                }
                str += "}";

                return str;

            }

            Behavior on x { enabled: bodyItem.initialized; NumberAnimation { duration: 850; easing.type: Easing.OutBack } }
            Behavior on y { enabled: bodyItem.initialized; NumberAnimation { duration: 850; easing.type: Easing.OutBack } }

            Item {
                id: positioner
                property var prevUpdateX
                property var prevUpdateY
                parent: nodeItem.parent

                Component.onCompleted: {
                    tmrSimStop.triggered.connect(updatePosition)
                }

                Component.onDestruction: {
                    tmrSimStop.triggered.disconnect(updatePosition)
                }

                function updatePosition()
                {
                    if (Math.abs(x - nodeItem.x) > 5) {
                        nodeItem.x = x;
                    }
                    if (Math.abs(y - nodeItem.y) > 5) {
                        nodeItem.y = y;
                    }
                }
            }

            RigidBody {
                id: bodyItem
                size:   nodeItem.size
                target: positioner
                position: Qt.point(0, 0)
                shape: RigidBody.Box
                density: gravityGraph.density
                linearDamping: gravityGraph.damping
                type: RigidBody.Dynamic

                onInitializedChanged: {
                    positioner.updatePosition();
                }
            }

            function each_child(func)
            {
                for (var i in linkedItems) {
                    func(linkedItems[i], i);
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                onClicked: {
                    gravityGraph.createChild(nodeItem);
                }
            }

            Loader {
                id: delegateLoader
                anchors.fill: parent
                sourceComponent: gravityGraph.delegate
                onLoaded: {
                    parent.delegate = this.item;
                    delegateLoader.item.container = nodeItem;
                }
            }
        }
    }

    Component {
        id: cmpLink
        Rectangle {
            id: link
            property Item  src
            property Item  dst
            property point p0: src ? src.center : Qt.point(0, 0)
            property point p1: dst ? dst.center : Qt.point(0, 0)
            property point delta: Qt.point(p1.x - p0.x, p1.y - p0.y)
            property alias joint: joint

            NumberAnimation on opacity {from: 0; to: 1; duration: 600}

            x: p1.x
            y: p1.y
            z: -1

            width: Math.sqrt(delta.x * delta.x + delta.y * delta.y)
            height: 1

            rotation: Utils.to_deg(-Math.atan2(p1.y - p0.y, p0.x - p1.x));
            transformOrigin: Item.Left

            gradient: Gradient {
                GradientStop { position: 0;    color: "transparent" }
                GradientStop { position: 0.25; color: "#dedede" }
                GradientStop { position: 0.75; color: "#dedede" }
                GradientStop { position: 1;    color: "transparent" }
            }

            DistanceJoint {
                id: joint
                length: gravityGraph.linkLength
                damping: 1
                function update()
                {
                    if (src && dst) {
                        joint.bodyA = src.body;
                        joint.bodyB = dst.body;
                        dst.parentLink = link;
                        visible = true;
                    } else {
                        visible = false;
                    }
                }
            }

            Component.onCompleted: {
                joint.update();
            }

            onSrcChanged: {
                joint.update();
            }

            onDstChanged: {
                joint.update();
            }
        }
    }

    PinchArea {
        width:  parent.width
        height: parent.height
        pinch {
            minimumScale: 3
            maximumScale: 15.
            target: flickable
        }
        Flickable {
            id: flickable
            property Item __contents: null

            anchors.centerIn: parent
            width:  parent.width
            height: parent.height
            topMargin: contentHeight
            leftMargin: contentWidth
            contentWidth:  __contents.width  * (Math.max(scale, 1) + 0.3)
            contentHeight: __contents.height * (Math.max(scale, 1) + 0.3)
            maximumFlickVelocity: 10000 * scale
            flickDeceleration: 1500 / scale
            scale: 4

            function contents()
            {
                if (!__contents) {
                    __contents = cmpContents.createObject(staticContents);
                }
                return __contents;
            }

            function clearContents()
            {
                if (__contents) {
                    __contents.destroy();
                    __contents = null;
                }
            }

            Item {
                id: staticContents
                width:  childrenRect.width
                height: childrenRect.height
            }

            Component {
                id: cmpContents
                Item {
                    width:  Math.max(childrenRect.width,  gravityGraph.width)
                    height: Math.max(childrenRect.height, gravityGraph.height)
                }
            }
        }
    }

    states: [
        State {
            name: "visible"
            PropertyChanges {
                target: gravityGraph
                opacity: 1
                scale: 1
                enabled: true
            }
        },

        State {
            name: "hidden"
            PropertyChanges {
                target: gravityGraph
                opacity: 0
                scale: 0.5
                enabled: false
            }
        }
    ]

    transitions: [
        Transition {
            to: "visible"
            SequentialAnimation {
                NumberAnimation { properties: "opacity,scale"; duration: 500; easing.type: Easing.OutBack }
            }
        },

        Transition {
            to: "hidden"
            SequentialAnimation {
                NumberAnimation { properties: "opacity,scale"; duration: 500; easing.type: Easing.InBack }
            }
        }
    ]
}
