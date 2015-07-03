function now()
{
    return new Date();
}

function startOfTheDay(date)
{
    var result = new Date(date);
    result.setHours(0);
    result.setMinutes(0);
    result.setSeconds(0);
    result.setMilliseconds(0);
    return result;
}

function startOfToday()
{
    return startOfTheDay(now());
}
