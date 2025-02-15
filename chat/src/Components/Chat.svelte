<script lang="ts">
    import { onDestroy, onMount } from "svelte";
    import { HtmlUtils } from "../Utils/HtmlUtils";
    import Loader from "./Loader.svelte";
    import { mucRoomsStore, xmppServerConnectionStatusStore } from "../Stores/MucRoomsStore";
    import UsersList from "./UsersList.svelte";
    import { MucRoom } from "../Xmpp/MucRoom";
    import { userStore } from "../Stores/LocalUserStore";
    import LL from "../i18n/i18n-svelte";
    import { localeDetector } from "../i18n/locales";
    import { locale } from "../i18n/i18n-svelte";
    import ChatLiveRooms from "./ChatLiveRooms.svelte";
    import { activeThreadStore } from "../Stores/ActiveThreadStore";
    import ChatActiveThread from "./ChatActiveThread.svelte";
    import ChatActiveThreadTimeLine from "./Timeline/ChatActiveThreadTimeline.svelte";
    import Timeline from "./Timeline/Timeline.svelte";
    import {
        availabilityStatusStore,
        connectionNotAuthorized,
        enableChat,
        showForumsStore,
        showLivesStore,
        showTimelineStore,
        showUsersStore,
        timelineActiveStore,
        timelineMessagesToSee,
    } from "../Stores/ChatStore";
    import { Unsubscriber, derived } from "svelte/store";
    import { chatConnectionManager } from "../Connection/ChatConnectionManager";
    import { ENABLE_OPENID } from "../Enum/EnvironmentVariable";
    import { iframeListener } from "../IframeListener";
    import { fly } from "svelte/transition";
    import NeedRefresh from "./NeedRefresh.svelte";
    import ChatForumRooms from "./ChatForumRooms.svelte";

    let chatWindowElement: HTMLElement;
    let handleFormBlur: { blur(): void };

    let searchValue = "";

    let defaultMucRoom: MucRoom | undefined = undefined;
    let subscribeListeners = new Array<Unsubscriber>();

    $: totalMessagesToSee = derived(
        [...[...$mucRoomsStore].map((mucRoom) => mucRoom.getCountMessagesToSee()), timelineMessagesToSee],
        ($totalMessagesToSee) => $totalMessagesToSee.reduce((sum, number) => sum + number, 0)
    );

    onMount(async () => {
        if (!$locale) {
            await localeDetector();
        }
        subscribeListeners.push(
            mucRoomsStore.subscribe(() => {
                try {
                    defaultMucRoom = mucRoomsStore.getDefaultRoom();
                } catch (e: unknown) {
                    console.error("Error get default room =>", e);
                }
            })
        );
        subscribeListeners.push(
            totalMessagesToSee.subscribe((total: number) => {
                iframeListener.sendChatTotalMessagesToSee(total);
            })
        );
        subscribeListeners.push(
            availabilityStatusStore.subscribe(() => {
                mucRoomsStore.sendPresences();
            })
        );
        subscribeListeners.push(
            mucRoomsStore.subscribe(() => {
                defaultMucRoom = mucRoomsStore.getDefaultRoom();
            })
        );
        subscribeListeners.push(
            showUsersStore.subscribe((value) => {
                if (value) {
                    showLivesStore.set(false);
                    showForumsStore.set(false);
                    showTimelineStore.set(false);
                }
            })
        );
        subscribeListeners.push(
            showLivesStore.subscribe((value) => {
                if (value) {
                    showUsersStore.set(false);
                    showForumsStore.set(false);
                    showTimelineStore.set(false);
                }
            })
        );
        subscribeListeners.push(
            showForumsStore.subscribe((value) => {
                if (value) {
                    showLivesStore.set(false);
                    showUsersStore.set(false);
                    showTimelineStore.set(false);
                }
            })
        );
        subscribeListeners.push(
            showTimelineStore.subscribe((value) => {
                if (value) {
                    showLivesStore.set(false);
                    showForumsStore.set(false);
                    showUsersStore.set(false);
                }
            })
        );
    });

    onDestroy(() => {
        subscribeListeners.forEach((listener) => {
            listener();
        });
    });

    function onClick(event: MouseEvent) {
        if (handleFormBlur && HtmlUtils.isClickedOutside(event, chatWindowElement)) {
            handleFormBlur.blur();
        }
    }

    function closeChat() {
        window.parent.postMessage({ type: "closeChat" }, "*");
        //document.activeElement?.blur();
    }
    function onKeyDown(e: KeyboardEvent) {
        if (e.key === "Escape") {
            closeChat();
        }
    }

    function login() {
        if (window.location !== window.parent?.location) {
            iframeListener.sendLogin();
        }
    }

    $: loading = !chatConnectionManager.connection || !$xmppServerConnectionStatusStore;

    $: loadingText = $userStore
        ? !chatConnectionManager.connection
            ? $LL.connecting()
            : $LL.waitingInit()
        : $LL.waitingData();

    console.info("Chat fully loaded");
</script>

<svelte:window on:keydown={onKeyDown} on:click={onClick} />

<aside class="chatWindow" bind:this={chatWindowElement}>
    <section class="tw-p-0 tw-m-0">
        {#if $connectionNotAuthorized}
            <NeedRefresh />
        {:else if loading}
            <Loader text={loadingText} />
        {:else if $timelineActiveStore}
            <ChatActiveThreadTimeLine on:unactiveThreadTimeLine={() => timelineActiveStore.set(false)} />
        {:else if $activeThreadStore !== undefined}
            <ChatActiveThread activeThread={$activeThreadStore} />
        {:else}
            <div class="wa-message-bg" transition:fly={{ x: -500, duration: 400 }}>
                <!-- searchbar -->
                <div class="tw-border tw-border-transparent tw-border-b-light-purple tw-border-solid">
                    <div class="tw-p-3">
                        <input
                            class="wa-searchbar tw-block tw-text-white tw-w-full placeholder:tw-text-sm tw-rounded-3xl tw-px-3 tw-py-1 tw-border-light-purple tw-border tw-border-solid tw-bg-transparent"
                            placeholder={$LL.search()}
                            bind:value={searchValue}
                        />
                    </div>
                </div>
                {#if !userStore.get().isLogged && ENABLE_OPENID}
                    <div class="tw-border tw-border-transparent tw-border-b-light-purple tw-border-solid">
                        <div class="tw-p-3 tw-text-sm tw-text-center">
                            <p>{$LL.signIn()}</p>
                            <button type="button" class="light tw-m-auto tw-cursor-pointer tw-px-3" on:click={login}>
                                {$LL.logIn()}
                            </button>
                        </div>
                    </div>
                {/if}
                <!-- chat users -->
                {#if defaultMucRoom !== undefined}
                    <UsersList mucRoom={defaultMucRoom} searchValue={searchValue.toLocaleLowerCase()} />
                {/if}

                {#if $enableChat}
                    <ChatForumRooms
                        searchValue={searchValue.toLocaleLowerCase()}
                        forumRooms={[...$mucRoomsStore].filter(
                            (mucRoom) => mucRoom.type === "forum" && mucRoom.name.toLowerCase().includes(searchValue)
                        )}
                    />
                    <ChatLiveRooms
                        searchValue={searchValue.toLocaleLowerCase()}
                        liveRooms={[...$mucRoomsStore].filter(
                            (mucRoom) => mucRoom.type === "live" && mucRoom.name.toLowerCase().includes(searchValue)
                        )}
                    />
                {/if}

                <Timeline on:activeThreadTimeLine={() => timelineActiveStore.set(true)} />
            </div>
        {/if}
    </section>
</aside>

<audio id="newMessageSound" src="/static/new-message.mp3" style="width: 0;height: 0;opacity: 0" />

<style lang="scss">
    aside.chatWindow {
        pointer-events: auto;
        color: whitesmoke;
        display: flex;
        flex-direction: column;
    }
</style>
