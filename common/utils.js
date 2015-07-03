function x(a)
{
    return a * mainWindow.scale;
}

function y(a)
{
    return a * mainWindow.scale;
}

function coord(a)
{
    return a * Math.min(mainWindow.scale, mainWindow.scale)
}

function length(p0, p1)
{
    var delta = Qt.point(p1.x - p0.x, p1.y - p0.y);
    return Math.sqrt(delta.x * delta.x + delta.y * delta.y);
}

function to_deg(val)
{
    return val / Math.PI * 180.;
}

function to_rad(val)
{
    return val / 180. * Math.PI;
}

function clamp(val, from, to)
{
    if (val < from)
    {
        return from;
    }

    if (val > to)
    {
        return to;
    }

    return val;
}

function humanReadable(val)
{
    var suffix = "";

    if (val > 999999)
    {
        val *= 1e-6;
        suffix = "M";
    }
    else if (val > 999)
    {
        val *= 1e-3;
        suffix = "k";
    }

    var str = "" + val;
    var parts = str.split(".");

    var result = parts[0];
    if (parts.length > 1 && parts[1].length > 1)
    {
        result += "." + parts[1][0];
    }
    else if (parts.length > 1)
    {
        result += "." + parts[1];
    }

    return result + suffix;
}
