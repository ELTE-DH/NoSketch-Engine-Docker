<features-tab-history class="card-content">
    <result-list></result-list>
</features-tab-history >

<features-tab-annotations class="card-content">
    <a href="#annotation?corpname={window.stores.app.data.corpus ? window.stores.app.data.corpus.corpname : ""}"
            class="btn">{_("an.manageAnnotations")}</a>
</features-tab-annotations>

<page-dashboard class="page-dashboard {bannerExpanded: bannerExpanded} {noBanner: hideBanner}">
    <div class="row {isAnonymous: !isFullAccount}">
        <div class="col xl7 l6 m12 s12">
            <div class="card dashboardCard corpusCard">
                <div if={corpus} class="card-content">
                    <div class="card-title">
                        <div class="titleWithButton">
                            <span class="title">
                                {corpus.name}
                            </span>
                            <div class="buttons center-align">
                                <a href="javascript:void(0);"
                                        id="btnCorpusInfo"
                                        class="white-text btn"
                                        onclick={SkE.showCorpusInfo.bind(null, corpus.corpname)}>
                                    {_("corpusInfo")}
                                </a>
                                <a if={window.permissions.ca}
                                        id="btnManageCorpus"
                                        href="#ca"
                                        class="white-text btn tooltipped"
                                        data-tooltip={_("db.menuTip")}>
                                    {_("manageCorpus")}
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="row" if={ready}>
                        <div class="col xl6 l12 m6 s12 {show-on-xlarge-only: !item.active}" each={item in activeItems} >
                            <a href={item.active && !item.oct ? ("#" + item.page + (item.query || "")) : ""}
                                    id="dashboard_btn{item.id}"
                                    class="text-primary"
                                    onclick={onCardClick}>
                                <div class={getClasses(item)}
                                        data-tooltip={item.active ? null : (item.tooltip ? item.tooltip : _("db.featureNotAvailable"))}>
                                    <i class="{item.iconClass || 'ske-icons'} {getFeatureIcon(item.id)} small">{item.icon}</i>
                                    <div class="card-content">
                                        <div class="featureName">
                                            {item.name || getFeatureLabel(item.id)}
                                        </div>
                                        <div class="featureDesc">
                                            {item.desc || _("db." + item.id + "Desc")}
                                        </div>
                                    </div>
                                </div>
                            </a>
                        </div>
                    </div>
                </div>
                <div if={!corpus || !ready} class="card-content">
                    <div class="notReady">
                        <i class="material-icons">storage</i>
                        <virtual if={!corpus}>
                            <h4>{_("noCorpus")}</h4>
                            <div class="note">{_("db.selectCorpus")}</div>
                            <br>
                            <a href="#corpus" class="btn white-text">{_("selectCorpus")}</a>
                        </virtual>
                        <virtual if={corpus}>
                            <virtual if={corpus.isCompiling && window.permissions["ca-compile"]}>
                                <h4>{_("ca.corpusBusy")}</h4>
                                <div class="note">{_("ca.compilingDesc")}</div>
                                <div class="progress">
                                    <div class="indeterminate"></div>
                                </div>
                                <br>
                                <a href="#ca-compile" class="btn white-text">{_("db.checkStatus")}</a>
                            </virtual>
                            <virtual if={corpus.isReady && window.permissions["ca-compile"]}>
                                 <h4>{_("db.toCompileTitle")}</h4>
                                <div class="note">{_("db.toCompileDesc")}</div>
                                <br>
                                <a href="#ca-compile" class="btn white-text">{_("ca.compile")}</a>
                            </virtual>
                            <virtual if={corpus.isEmpty && window.permissions["ca-add-content"]}>
                                 <h4>{_("db.emptyTitle")}</h4>
                                <div class="note">{_("db.emptyDesc")}</div>
                                <br>
                                <a href="#ca-add-content" class="btn white-text">{_("addTexts")}</a>
                            </virtual>
                            <virtual if={corpus.isCompilationFailed && window.permissions["ca-compile"]}>
                                 <h4>{_("compilation_failed")}</h4>
                                <div class="note">{_("ca.compilation_failedDesc")}</div>
                                <br>
                                <a href="#ca-compile" class="btn white-text btn-primary">{_("compile")}</a>
                            </virtual>
                        </virtual>
                    </div>
                </div>
            </div>
        </div>

        <div class="col xl5 l6 m12 s12" if={isFullAccount}>
            <div class="card dashboardCard recentCorpora">
                <div class="card-content">
                    <div class="card-title">
                        <div class="titleWithButton">
                            <span class="title">
                                {_("db.recentCorpora")}
                            </span>
                            <a href="#ca-create" if={window.permissions["ca-create"]} class="btn white-text">
                                {_("newCorpus")}
                            </a>
                        </div>
                    </div>
                    <corpus-history></corpus-history>
                </div>
            </div>

            <div if={!hideBanner}
                    class="banner center-align">
                <h5>If you use the corpora for your work, please cite the corresponding publication.</h5>
                <br>
                <a href="CITATION_LINK_PLACEHOLDER"
                        class="btn"
                        target="_blank">The list of publications recommended to cite</a>
                <br>
            </div>
            <!--div class="banner bigBanner center-align">
                <a class="btn btn-floating btn-flat right" onClick={onBannerToggleClick}>
                    <i class="material-icons bigBanner">keyboard_arrow_up</i>
                </a>
                <img src="images/boot_camp.png" loading="lazy">
                <h5>2 days of corpus searching &amp; corpus building</h5>
                <div>Learn to work with Sketch Engine like a pro!</div>
                <br>
                <a href={externalLink("bootCamp")}
                        class="btn"
                        target="_blank">{_("detailsAndReg")}</a>
                <br>
            </div>
            <div class="banner smallBanner center-align" onClick={onBannerToggleClick}>
                <a class="btn btn-floating btn-flat right">
                    <i class="material-icons smallBanner">keyboard_arrow_down</i>
                </a>
                <h5>Master the interface in 2 days!</h5>
                <div>March & April 2020</div>
            </div-->
        </div>
        <div class="col s12" if={isFullAccount}>
            <div class="card dashboardCard history">
                <ui-tabs tabs={tabs} name="tabs-history"></ui-tabs>
            </div>
        </div>
    </div>


    <script>
        require("./page-dashboard.scss")
        require("./corpus-history.tag")
        require("./result-list.tag")
        const {AppStore} = require("core/AppStore.js")
        const {Url} = require("core/url.js")
        const {Auth} = require("core/Auth.js")

        this.mixin("tooltip-mixin")

        this.isFullAccount = Auth.isFullAccount()
        this.bannerExpanded = true
        this.hideBanner = window.config.HIDE_DASHBOARD_BANNER
        this.bannerId = Math.ceil(Math.random() * 3)

        _isBitermsActive(){
            if(!this.corpus
                    || (this.corpus.owner_id === null && !this.corpus.corpname.includes("_oct"))
                    || (!this.corpus.aligned || this.corpus.aligned.length == 0)
                    || !AppStore.langsWithBiterms.includes(this.corpus.language_name)){
                return false
            }
            let compatibleCorpora = AppStore.data.corpusList.filter(c => AppStore.langsWithBiterms.includes(c.language_name))
                    .map(c => c.corpname.split("/").splice(-1).join("/"))
            return this.corpus.aligned.some(c => compatibleCorpora.includes(c))
        }

        _updateItems() {
            this.corpus = AppStore.get("corpus")
            this.ready = AppStore.get("ready")
            let wlattr = AppStore.getFirstWlattr()
            let features = AppStore.get("features")
            let p = window.permissions
            this.items = [
                {
                    page: "wordsketch",
                    id: "wordsketch",
                    active: p.wordsketch && features.wordsketch
                }, {
                    page: "sketchdiff",
                    id: "sketchdiff",
                    active: p.sketchdiff && features.sketchdiff
                }, {
                    page: "thesaurus",
                    id: "thesaurus",
                    active: p.thesaurus && features.thesaurus
                }, {
                    page: "concordance",
                    id: "concordance",
                    active: p.concordance && features.concordance
                }, {
                    page: "parconcordance",
                    id: "parconcordance",
                    tooltip: "t_id:d_parconc_inactive",
                    active: p.parconcordance && features.parconcordance
                }, {
                    page: "wordlist",
                    id: "wordlist",
                    active: p.wordlist && features.wordlist
                }, {
                    page: "ngrams",
                    id: "ngrams",
                    active: p.ngrams && features.ngrams
                }, {
                    page: "keywords",
                    id: "keywords",
                    active: p.keywords && features.keywords
                }, {
                    page: "trends",
                    id: "trends",
                    active: p.trends && features.trends
                }, {
                    page: "text-type-analysis",
                    query: this.corpus ? `?corpname=${this.corpus.corpname}&wlminfreq=1&include_nonwords=1&showresults=1&wlicase=1&wlnums=frq&wlattr=${wlattr}` : "",
                    iconClass: "material-icons rotate180",
                    icon: "donut_small",
                    id: "tta",
                    name: _("tta"),
                    desc: _("ttaDesc"),
                    active: p.tta && features.wordlist && wlattr
                }, {
                    page: "ocd",
                    id: "ocd",
                    active: p.ocd && features.ocd
                }, {
                    oct: true,
                    id: "octerms",
                    active: this._isBitermsActive(),
                    tooltip: "t_id:d_octerms_inactive"
                }
            ]
            this.activeItems = []
            this.inactiveItems = []
            this.items.forEach(item => {
                if(!isDef(p[item.id]) || p[item.id]){
                    this.activeItems.push(item)
                } else {
                    this.inactiveItems.push(item)
                }
            })
        }
        this._updateItems()

        _updateUrl(){
            let urlQuery = Url.getQuery()
            if(this.corpus && this.corpus.corpname){
                urlQuery.corpname = this.corpus.corpname
            }
            history.replaceState(null, null, Url.create("dashboard", urlQuery))
        }

        this.tabs = [{
            tabId: "history",
            labelId: "db.recentResults",
            tag: "features-tab-history"
        }, {
            tabId: "annotations",
            labelId: "an.annotations",
            tag: "features-tab-annotations"
        }]

        getClasses(item){
            return{
                card: 1,
                small: 1,
                horizontal: 1,
                active: item.active,
                inactive: !item.active,
                hover: item.active,
                tooltipped: !item.active,
            }
        }

        onCardClick(evt){
            let item = evt.item.item
            if(!item.active){
                evt.preventDefault()
                return
            }
            if(!item.oct) {
                Dispatcher.trigger("RESET_STORE", item.page)
            }
            else{
                Dispatcher.trigger("openDialog", {
                    title: _("bitermsDialogTitle"),
                    tag: "oct-langs",
                    class: "no-print"
                })
            }

        }

        onBannerToggleClick(evt){
            evt.preventUpdate = true
            this.bannerExpanded = !this.bannerExpanded
            $(this.root).toggleClass("bannerExpanded", this.bannerExpanded)
        }

        getInactiveItemTooltip(item){
            let name = item.name || getFeatureLabel(item.id)
            let desc = item.desc || _("db." + item.id + "Desc")
            return `<b>${name}</b><br>${desc}`
        }

        this.on("update", this._updateItems)

        this.on("updated", this._updateUrl)

        this.on("mount", () => {
            this._updateUrl()
            AppStore.on("corpusChanged", this.update)
        })

        this.on("unmount", () => {
            AppStore.off("corpusChanged", this.update)
        })

    </script>
</page-dashboard>
