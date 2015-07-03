WorkerScript.onMessage = function(message)
{
    var model = message.model;
    var rows = message.rows;
    model.clear();

    for (var i = 0; i < rows.length; ++i)
    {
        var row = message.rows[i];
        model.append(row);
    }

    model.sync();
    WorkerScript.sendMessage({});
}
