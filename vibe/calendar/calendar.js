function parseTimeTo24h( timeStr )
{
    const match = timeStr.toLowerCase().match(/^(\d+)(?::(\d+))?\s*(am|pm)$/);
    if(!match)
    {
        console.warn(`Could not parse time string: "${timeStr}", defaulting to 00:00`);
        return "00:00";
    }

    let hours = parseInt(match[1], 10);
    const minutes = match[2] ? match[2].padStart(2, '0') : "00";
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

// returns the correct UTC offset string for Pacific time on a given
// YYYY-MM-DD date, accounting for DST (PDT -07:00 vs PST -08:00)
function getPacificOffset(isoDateStr)
{
    const probeDate = new Date(`${isoDateStr}T12:00:00Z`);

    if(isNaN(probeDate.getTime()))
    {
        console.warn(`getPacificOffset received an invalid date: "${isoDateStr}", defaulting to -08:00`);
        return "-08:00";
    }

    const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone: 'America/Los_Angeles',
        timeZoneName: 'shortOffset'
    });

    const offsetPart = formatter.formatToParts(probeDate)
        .find(part => part.type === 'timeZoneName')?.value;

    const match = offsetPart ? offsetPart.match(/GMT([+-]\d+)/) : null;
    const offsetHours = match ? parseInt(match[1], 10) : -8;

    const sign = offsetHours < 0 ? '-' : '+';
    const absHours = String(Math.abs(offsetHours)).padStart(2, '0');

    return `${sign}${absHours}:00`;
}

function happeningNow(event)
{
    const now = new Date();
    return event.startDateObj <= now && event.endDateObj >= now;
}

function renderTable(eventsJson)
{
    const now = new Date();
    const eventTable = document.getElementById('event-table');
    const showSltLabel = !isUserInSLT();

    // format using user's automated system locale config
    const dateFormatter = new Intl.DateTimeFormat(navigator.language, { dateStyle: 'full' });
    const timeFormatter = new Intl.DateTimeFormat(navigator.language, { timeStyle: 'short'});

    const processedEvents = eventsJson
        .map(event => {
            try {
                const start24 = parseTimeTo24h(event.startTime);
                const end24 = parseTimeTo24h(event.endTime);

                const dateMatch = String(event.date).trim().match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
                if(!dateMatch)
                {
                    console.warn(`Skipping event with unparseable date:`, event);
                    return null;
                }
                const [, month, day, year] = dateMatch;
                const isoDate = `${year}-${month.padStart(2,'0')}-${day.padStart(2,'0')}`;

                const offset = getPacificOffset(isoDate);
                const startIso = `${isoDate}T${start24}:00${offset}`;
                const endIso = `${isoDate}T${end24}:00${offset}`;

                const startDateObj = new Date(startIso);
                const endDateObj = new Date(endIso);

                if(isNaN(startDateObj) || isNaN(endDateObj))
                {
                    console.warn(`Skipping event with invalid resulting date:`, event, { startIso, endIso });
                    return null;
                }

                return { title: event.title, startDateObj, endDateObj };
            } catch(err) {
                console.warn(`Error processing event, skipping:`, event, err);
                return null;
            }
        })
    .filter(event => event !== null)
    .sort((a, b) => a.startDateObj - b.startDateObj)
    .filter(event => event.endDateObj > now)

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
                            ${showSltLabel ? '<span style="text-transform: none">(SLT)</span>' : ''}
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
        const bgColorNext = getComputedStyle(document.documentElement).getPropertyValue('--brass');
        const bgColorNow = getComputedStyle(document.documentElement).getPropertyValue('--bg-main-light');

        let html = '';
        let eventLabel = happeningNow(event) ? 'Happening Now' : 'Next';
        let element = document.getElementById('up-next');

        if( index === 0 )
        {
            if( happeningNow(event) )
            {
                element.style.setProperty('background-color', bgColorNow);
            }
            else
            {
                element.style.setProperty('background-color', bgColorNext);
            }
            html += `
                <p style="font-weight:bold;">${eventLabel}: ${event.title}</p>
                <p style="font-size: 0.8em; font-weight:lighter">${localDate}, ${localStart} - ${localEnd}${showSltLabel ? ' (SLT)' : ''}</p>
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