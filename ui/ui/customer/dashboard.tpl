{include file="customer/header.tpl"}
<!-- user-dashboard -->

{function showWidget pos=0}
    {foreach $widgets as $w}
        {if $w['position'] == $pos}
            {$w['content']}
        {/if}
    {/foreach}
{/function}


{assign rows explode(".", $_c['dashboard_Customer'])}
{assign pos 1}
{foreach $rows as $cols}
    {if $cols == 12}
        <div class="row">
            <div class="col-md-12">
                {showWidget widgets=$widgets pos=$pos}
            </div>
        </div>
        {assign pos value=$pos+1}
    {else}
        {assign colss explode(",", $cols)}
        <div class="row">
            {foreach $colss as $c}
                <div class="col-md-{$c}">
                    {showWidget widgets=$widgets pos=$pos}
                </div>
                {assign pos value=$pos+1}
            {/foreach}
        </div>
    {/if}
{/foreach}


{if isset($hostname) && $hchap == 'true' && $_c['hs_auth_method'] == 'hchap'}
<div id="authApp">
    <div class="row">
        <div class="col-md-6 col-md-offset-3 text-center">
            <div class="panel panel-primary">
                <div class="panel-body" style="padding: 25px;">
                    <h3><i class="fa fa-wifi"></i> Connecting to Internet...</h3>
                    <div class="progress" style="height: 10px; margin: 20px 0;">
                        <div class="progress-bar progress-bar-striped active" role="progressbar" style="width: 100%"></div>
                    </div>
                    <p id="statusMessage">Please wait while we connect you...</p>
                    <div id="retryButton" style="display: none; margin-top: 15px;">
                        <button onclick="window.location.reload()" class="btn btn-primary">Try Again</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script type="text/javascript" src="/ui/ui/scripts/md5.js"></script>
    <script type="text/javascript">
        (function() {
            var hostname = "http://{$hostname}/login";
            var user = "{$_user['username']}";
            var pass = "{$_user['password']}";
            var dst = "{$apkurl}";
            var key = hexMD5('{$key1}' + pass + '{$key2}');
            var isAuthComplete = false;

            var authUrl = hostname + '?username=' + encodeURIComponent(user) +
                '&dst=' + encodeURIComponent(dst) +
                '&password=' + encodeURIComponent(key);

            var authFrame = document.createElement('iframe');
            authFrame.style.display = 'none';
            document.body.appendChild(authFrame);

            function updateStatus(message) {
                document.getElementById('statusMessage').innerText = message;
            }

            async function checkConnection() {
                if (isAuthComplete) return false;
                try {
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => controller.abort(), 3000);
                    await fetch('https://www.google.com/generate_204', { mode: 'no-cors', signal: controller.signal });
                    clearTimeout(timeoutId);
                    return true;
                } catch (error) {
                    return false;
                }
            }

            function cleanup() {
                if (authFrame) { authFrame.remove(); }
            }

            function handleSuccess() {
                if (!isAuthComplete) {
                    isAuthComplete = true;
                    cleanup();
                    updateStatus('Connected successfully');
                }
            }

            async function tryAuthentication(attempt) {
                if (isAuthComplete) return true;
                return new Promise(async function(resolve) {
                    updateStatus('Attempt ' + attempt + ' of 3: Connecting to network...');
                    authFrame.src = authUrl;
                    await new Promise(r => setTimeout(r, 3000));
                    for (let check = 0; check < 3; check++) {
                        if (isAuthComplete) { resolve(true); return; }
                        const isConnected = await checkConnection();
                        if (isConnected) { handleSuccess(); resolve(true); return; }
                        await new Promise(r => setTimeout(r, 1000));
                    }
                    resolve(false);
                });
            }

            async function authenticate() {
                try {
                    if (await checkConnection()) { handleSuccess(); return; }
                    for (let i = 1; i <= 3; i++) {
                        if (await tryAuthentication(i)) return;
                        if (i < 3 && !isAuthComplete) await new Promise(r => setTimeout(r, 2000));
                    }
                    if (!isAuthComplete) {
                        updateStatus('Unable to connect. Please ensure you have an active subscription or contact support.');
                        document.getElementById('retryButton').style.display = 'block';
                        cleanup();
                    }
                } catch (error) {
                    if (!isAuthComplete) {
                        updateStatus('Connection error. Please check your subscription or contact support.');
                        document.getElementById('retryButton').style.display = 'block';
                        cleanup();
                    }
                }
            }

            authenticate();
        })();
    </script>
</div>
{/if}
{include file="customer/footer.tpl"}