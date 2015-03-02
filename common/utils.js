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
