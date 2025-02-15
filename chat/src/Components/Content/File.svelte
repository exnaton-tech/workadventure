<script lang="ts">
    import { FileIcon, EyeIcon, DownloadCloudIcon, LoaderIcon } from "svelte-feather-icons";
    import LL from "../../i18n/i18n-svelte";
    import { iframeListener } from "../../IframeListener";
    import { FileMessageManager } from "../../Services/FileMessageManager";

    export let url: string;
    export let name: string | undefined;

    function openCoWebsite() {
        iframeListener.openCoWebsite(url, true, "allowfullscreen");
    }

    let loadingDownload = false;
    function download() {
        loadingDownload = true;
        fetch(url, { method: "GET" })
            .then((res) => {
                return res.blob();
            })
            .then((blob) => {
                var url = URL.createObjectURL(blob);
                var a = document.createElement("a");
                a.href = url;
                a.download = name ?? FileMessageManager.getName(url);
                document.body.appendChild(a);
                a.click();
                setTimeout((_) => {
                    URL.revokeObjectURL(url);
                }, 60000);
                a.remove();
                loadingDownload = false;
            })
            .catch((err) => {
                loadingDownload = false;
                console.error("err: ", err);
            });
    }
</script>

<div class="file">
    {#if FileMessageManager.isImage(url)}
        <img src={url} width="100%" height="100%" alt={name ?? FileMessageManager.getName(url)} class="tw-mt-2" />
    {:else if FileMessageManager.isVideo(url)}
        <video width="100%" height="100%" alt={name ?? FileMessageManager.getName(url)} class="tw-mt-2" controls>
            <track kind="captions" srclang="en" label="english_captions" src="" />
            <source src={url} type={`video/${FileMessageManager.getExtension(url)}`} />
            Sorry, your browser doesn't support <code>embedded</code> videos.
        </video>
    {:else if FileMessageManager.isSound(url)}
        <audio width="100%" height="100%" controls class="tw-mt-2" src={url}>
            Your browser does not support the <code>audio</code> element.
        </audio>
    {:else}
        <div class="other-content tw-rounded-lg tw-cursor-pointer" on:click={download}>
            <div class="icon tw-p-0 tw-mr-1">
                <FileIcon size="30" />
            </div>
            <div class="information">
                <p class="tw-m-0">{name ?? FileMessageManager.getName(url)}</p>
                <!--
                <p class="tw-text-light-purple-alt tw-mt-1 tw-m-0 tw-text-xxs">
                    {link.size ?? "0"}kb - {link.lastModified
                        ? new Date(link.lastModified).toLocaleDateString()
                        : new Date().toLocaleDateString()}
                </p>
                -->
            </div>
        </div>
    {/if}

    <div class="actions tw-mt-2">
        <span class="action wa-dropdown-item" on:click={openCoWebsite}>
            <EyeIcon size="14" />
            <span class="tw-ml-1 tw-text-xxs">{$LL.file.openCoWebsite()}</span>
        </span>
        <span class="action wa-dropdown-item" on:click={download}>
            {#if loadingDownload === true}
                <LoaderIcon size="14" class="tw-animate-spin" />
            {:else}
                <DownloadCloudIcon size="14" />
            {/if}
            <span class="tw-ml-1 tw-text-xxs">{$LL.file.download()}</span>
        </span>
    </div>
</div>

<style lang="scss">
    .file {
        position: relative;
        &:hover {
            .actions {
                display: flex;
            }
        }

        .actions {
            display: none;
            position: absolute;
            top: 0px;
            padding: 0px;
            cursor: pointer;
            flex-direction: column;
            border-radius: 0.25rem;
            border-width: 1px;
            border-style: solid;
            --tw-border-opacity: 1;
            border-color: rgb(77 75 103 / var(--tw-border-opacity));
            background-color: rgb(27 27 41 / 0.95);
            font-size: 0.75rem;
            line-height: 1rem;
            font-weight: 500;
            color: rgb(255 255 255 / var(--tw-text-opacity));
            --tw-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
            --tw-shadow-colored: 0 10px 15px -3px var(--tw-shadow-color), 0 4px 6px -4px var(--tw-shadow-color);
            box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);
            z-index: 1;

            .action {
                display: flex;
                flex-direction: row;
                align-items: center;
                padding: 4px;
                border-radius: 0.15rem;

                & > span {
                    display: none;
                }

                &:hover {
                    --tw-bg-opacity: 1;
                    background-color: rgb(77 75 103 / var(--tw-bg-opacity));
                }
            }

            &:hover {
                span.action > span {
                    display: block;
                }
            }
        }

        .other-content {
            position: relative;
            display: flex;
            flex-direction: row;
            align-items: center;
            --tw-bg-opacity: 1;
            border: solid 1px rgb(77 75 103 / var(--tw-bg-opacity));
            &:hover {
                background-color: rgb(77 75 103 / var(--tw-bg-opacity));
            }
        }

        audio {
            max-width: 100%;
        }
    }
</style>
