--[[

  Cyren AntiSpam gateway lookup for rspamd
  Copyleft 2018 Sébastien RICCIO / SwissCenter

  Version: 1.0

--]]
local logger = require "rspamd_logger"
local http = require "rspamd_http"
local regexp = require "rspamd_regexp"

local N = "cyren"
local symbol_cyren = "CYREN_CALLBACK"
local opts = rspamd_config:get_all_opt(N)

-- Default settings
local cfg_url = "http://localhost:8088"

local function check_cyren(task)
    local function check_cyren_cb(err, code, body, headers)
        if err then
            logger.errx(task, "HTTP request to Cyren gateway error: %s", err)
            return
        end

        -- Parse body for relevant cyren responses
        local response_cyren_headers = {}
        local re, re_result

        re = regexp.create('/^(X-CTCH-.*): (.*)$/m')
        re_result = re:search(body, false, true)
        if re_result then
            for index in ipairs(re_result)do
                response_cyren_headers[re_result[index][2]] = re_result[index][3]
            end
        end

        if response_cyren_headers['X-CTCH-Spam'] then
            task:insert_result('CYREN_' .. string.upper(response_cyren_headers['X-CTCH-Spam']), 1)
        end
    end

    -- Getting some useful informations about the mail being checked
    local mail_from
    if task:has_from('smtp') then
        mail_from = task:get_from('smtp')[1]
    end
    if task:has_from('mime') then
        mail_from = task:get_from('mime')[1]
    end
    local client_host = task:get_from_ip()

    -- Preparing body for http post to cyren gateway
    local body = ""
    body = body .. string.format("X-CTCH-PVer: %s\n", '0000001')
    body = body .. string.format("X-CTCH-MailFrom: %s\n", mail_from['addr'])
    body = body .. string.format("X-CTCH-SenderIP: %s\n", client_host)

    -- Adding original message body
    body = body .. string.format("\n%s", task:get_content())

    -- Querying gateway
    logger.info(logger.slog("Querying cyren gateway at %s with from %s and client ip %s. Hold on tight!", cfg_url, mail_from['addr'], client_host))
    http.request({
        task = task,
        url = cfg_url,
        body = body,
        callback = check_cyren_cb,
        headers = headers,
        mime_type = 'text/plain',
    })
end

if opts then
    -- Loading options from config files
    if opts.url then
        cfg_url = opts.url
    end

    local id = rspamd_config:register_symbol({
        name = symbol_cyren,
        callback = check_cyren
    })

    rspamd_config:register_symbol({
        name = 'CYREN_UNKNOWN',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_BULK',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_VALIDBULK',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_SUSPECT',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_CONFIRMED',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_HIGH',
        parent = id,
        type = 'virtual'
    })
    rspamd_config:register_symbol({
        name = 'CYREN_VIRUS',
        parent = id,
        type = 'virtual'
    })

    logger.infox("%s module is configured and loaded! Youhouu!", N)
else
    logger.infox("%s module not configured, too bad.", N)
end
