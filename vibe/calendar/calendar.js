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
    const timeFormatter = new Intl.DateTimeFormat(navigator.language, { timeStyle: 'short'});

    const processedEvents = eventsJson
        // map events to proper ISO dates/times
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
        // sort chronologically by start time
        .sort((a, b) => a.startDateObj - b.startDateObj)
        // discard any events that are past or are at index 0
        .filter( event => event.endDateObj > now )

    // build out the html table rows
    eventTable.innerHTML = processedEvents.map( (event, index) => {
        // format text into localized date & time
        const localDate = dateFormatter.format(event.startDateObj);
        const localStart = timeFormatter.format(event.startDateObj);
        const localEnd = timeFormatter.format(event.endDateObj);

        let html = '';

        if( index != 0 )
        {
            html += `
                <tr>
                    <td>${event.title}</td>
                    <td class="date-label">
                        ${localDate}<br>
                        <span class="time-label">${localStart} - ${localEnd}
                            <!-- <span style="text-transform: none">(SLT)
                            </span> -->
                        </span>
                    </td>
                </tr>
            `;
        }

        return html;
    }).join('');

    upNext.innerHTML = processedEvents.map( (event, index) => {
        const localDate = dateFormatter.format(event.startDateObj);
        const localStart = timeFormatter.format(event.startDateObj);
        const localEnd = timeFormatter.format(event.endDateObj);

        let html = '';
        
        if( index === 0 )
        {
            html += `
                <p style="font-weight:bold;">Next: ${event.title}</p>
                <p style="font-size: 0.8em; font-weight:lighter">${localDate}, ${localStart} - ${localEnd}</p>
            `;
        }
        return html;
    }).join('');
}

const eventTable = document.getElementById('event-table');
const upNext = document.getElementById('up-next');
let htmlRows = '';

// fetch the JSON data from the file path
fetch('calendarData.json', {cache: 'no-store'})
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
        console.log("Properly fetched JSON file. Rendering new table.");
        renderTable(eventsJson);
    })
    .catch(error => console.error('Error fetching or processing JSON: ', error));
