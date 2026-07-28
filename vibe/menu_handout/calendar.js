/*            const p = new URLSearchParams(location.search);
            let cfg = {};
            try { cfg = JSON.parse(p.get("data") || "{}"); }
            catch (e) { console.error("Bad config JSON:", e); }

            if (cfg.title)    document.getElementById("title").textContent    = cfg.title;
            if (cfg.subtitle) document.getElementById("subtitle").textContent = cfg.subtitle;
            if (cfg.theme)    document.body.dataset.theme = cfg.theme;
            if (Array.isArray(cfg.hours))
                document.getElementById("hours").innerHTML =
                cfg.hours.map(h => `<li>${h}</li>`).join("");
*/

function parseTimeTo24h( timeStr )
{
    const match = timeStr.toLowerCase().match(/^(\d+)(?::(\d+))?\s*(am|pm)$/);
    if(!match) return "00:00";

    let hours = parseInt(match[1], 10);
    const minutes = match[2] ? match[2] : "00";
    const ampm = match[3];

    if(ampm === "pm" && hours < 12) hours += 12;
    if(ampm === "am" && hours === 12) hours = 0;

    return `${String(hours).padStart(2, '0')}:${minutes}`;
}

function isUserInSLT()
{
    const userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    return userTimeZone === 'America/Los_Angeles';
}

function renderTable(eventsJson)
{
    const now = new Date();
    const eventTable = document.getElementById('event-table');

    // format using user's automated system locale config
    const dateFormatter = new Intl.DateTimeFormat(navigator.language, { dateStyle: 'full' });
    const timeFormatter = new Intl.DateTimeFormat(navigator.language, {timeStyle: 'short'});

    const processedEvents = eventsJson
        .map(event => {
            // convert "7pm" -> "19:00"
            const start24 = parseTimeTo24h(event.startTime);
            const end24 = parseTimeTo24h(event.endTime);

            // build ISO string assuming source is pacific time (SLT)
            const startIso = `${event.date}T${start24}:00-07:00`;
            const endIso = `${event.date}T${end24}:00-07:00`;

            return {
                title: event.title,
                startDateObj: new Date(startIso),
                endDateObj: new Date(endIso)
            };
        })
        // discard any events that are past
        .filter( event => event.endDateObj > now )
        // sort chronologically by start time
        .sort((a, b) => a.startDateObj - b.startDateObj);

    // build out the html table rows
    eventTable.innerHTML = processedEvents.map( event => {
        // format text into localized date & time
        const localDate = dateFormatter.format(event.startDateObj);
        const localStart = timeFormatter.format(event.startDateObj);
        const localEnd = timeFormatter.format(event.endDateObj);

        let html = '';

        if( isUserInSLT() )
        {
            html += `
                <tr>
                    <td>${event.title}</td>
                    <td class="date-label">${localDate}<br><span class="time-label">${localStart} - ${localEnd} <span style="text-transform: none">(SLT)</span></span></td>
                </tr>
            `;
        }
        else
        {
            html += `
                <tr>
                    <td>${event.title}</td>
                    <td class="date-label">${localDate}<br><span class="time-label">${localStart} - ${localEnd}</span></td>
                </tr>
            `;
        }

        return html;
    }).join('');
}

const eventTable = document.getElementById('event-table');
let htmlRows = '';

// fetch the JSON data from the file path
fetch('calendarData.json')
    .then(response => 
    {
        if(!response.ok) 
        {
            throw new Error('Network response error');
        }
        return response.json();
    })
    .then(eventsJson =>
    {
        renderTable(eventsJson);
    })
    .catch(error => console.error('Error fetching or processing JSON: ', error));
