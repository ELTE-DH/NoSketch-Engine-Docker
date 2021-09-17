<features-tab-history class="card-content">
    <result-list section="history"></result-list>
</features-tab-history >

<features-tab-favourites class="card-content">
    <result-list section="favourites"></result-list>
</features-tab-favourites>

<features-tab-annotations class="card-content">
    <result-list section="annotations"></result-list>
</features-tab-annotations>

<page-dashboard class="page-dashboard {bannerExpanded: bannerExpanded}">
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
                                        class="white-text btn"
                                        onclick={SkE.showCorpusInfo.bind(null, corpus.corpname)}>
                                    {_("corpusInfo")}
                                </a>
                                <a if={window.permissions.ca}
                                        href="#ca"
                                        class="white-text btn tooltipped"
                                        data-tooltip={_("db.menuTip")}>
                                    {_("manageCorpus")}
                                </a>
                                <a href={window.config.URL_SKEMA + "?corpname=" + corpus.corpname}
                                        if={agroup && window.config.URL_SKEMA}
                                        target="_blank"
                                        class="btn">{_("skema")}
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="row" if={ready}>
                        <div class="col xl6 l12 m6 s12 {show-on-xlarge-only: !item.active}" each={item in items} >
                            <a href={item.active ? ("#" + item.page) : ""} id="dashboard_btn{item.id}" class="text-primary" onclick={onCardClick}>
                                <div class={getClasses(item)} data-tooltip={item.active ? null : _("db.featureNotAvailable")}>
                                    <i class="ske-icons {getFeatureIcon(item.id)} small"></i>
                                    <div class="card-content">
                                        <div class="featureName">
                                            {getFeatureLabel(item.id)}
                                        </div>
                                        <div class="featureDesc">
                                            {_("db." + item.id + "Desc")}
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
                                 <h4>{_("ca.compilation_failed")}</h4>
                                <div class="note">{_("ca.compilation_failedDesc")}</div>
                                <br>
                                <a href="#ca-compile" class="btn white-text contrast">{_("compile")}</a>
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

            <div class="banner bigBanner center-align">
                <a class="btn btn-floating btn-flat right" onClick={onBannerToggleClick}>
                    <i class="material-icons bigBanner">keyboard_arrow_up</i>
                </a>
                <h5>If you use the corpora for your work, please cite the corresponding publication.</h5>
                <br>
                <a href="CITATION_LINK_PLACEHOLDER"
                        class="btn"
                        target="_blank">The list of publications recommended to cite</a>
                <br>
            </div>
            <div class="banner smallBanner center-align" onClick={onBannerToggleClick}>
                <a class="btn btn-floating btn-flat right">
                    <i class="material-icons smallBanner">keyboard_arrow_down</i>
                </a>
                <h5>The service is for non-profit scientific purposes only</h5>
                <div>Read further for citing info</div>
            </div>
        </div>
        <div class="col s12" if={isFullAccount}>
            <div class="card dashboardCard">
                <ui-tabs tabs={tabs} name="tabs-history"></ui-tabs>
            </div>
        </div>
    </div>


    <script>
        require("./page-dashboard.scss")
        require("./corpus-history.tag")
        require("./result-list.tag")
        const {AppStore} = require("core/AppStore.js")
        const {Router} = require("core/Router.js")
        const {Auth} = require("core/Auth.js")

        this.mixin("tooltip-mixin")

        this.isFullAccount = Auth.isFullAccount()
        this.bannerExpanded = false
        this.agroup = Auth.getAnnotationGroup()

        _updateItems() {
            this.corpus = AppStore.get("corpus")
            this.ready = AppStore.get("ready")
            let features = AppStore.get("features")
            let p = window.permissions
            this.items = [
                {
                    page: "wordsketch",
                    desc: "db.wordSketchDesc",
                    icon: "skeico_word_sketch",
                    id: "wordsketch",
                    active: p.wordsketch && features.wordsketch
                }, {
                    page: "sketchdiff",
                    icon: "skeico_word_sketch_difference",
                    id: "sketchdiff",
                    active: p.sketchdiff && features.sketchdiff
                }, {
                    page: "thesaurus",
                    icon: "skeico_thesaurus",
                    id: "thesaurus",
                    active: p.thesaurus && features.thesaurus
                }, {
                    page: "concordance",
                    icon: "skeico_concordance",
                    id: "concordance",
                    active: p.concordance && features.concordance
                }, {
                    page: "parconcordance",
                    icon: "skeico_parallel_concordance",
                    id: "parconcordance",
                    active: p.parconcordance && features.parconcordance
                }, {
                    page: "wordlist",
                    desc: "db.wordlistDesc",
                    icon: "skeico_word_list",
                    id: "wordlist",
                    active: p.wordlist && features.wordlist
                }, {
                    page: "ngrams",
                    icon: "skeico_n_grams",
                    id: "ngrams",
                    active: p.ngrams && features.ngrams
                }, {
                    page: "keywords",
                    icon: "skeico_keywords",
                    id: "keywords",
                    active: p.keywords && features.keywords
                }, {
                    page: "trends",
                    icon: "skeico_trends",
                    id: "trends",
                    active: p.trends && features.trends
                }, {
                    page: "ocd",
                    icon: "skeico_ocd",
                    id: "ocd",
                    active: p.ocd && features.ocd
                }
            ]
        }
        this._updateItems()

        _updateUrl(){
            let urlQuery = {}
            if(this.corpus && this.corpus.corpname){
                urlQuery = {
                    corpname: this.corpus.corpname
                }
            }
            history.replaceState(null, null, Router.createUrl("dashboard", urlQuery))
        }

        this.tabs = [{
            tabId: "history",
            labelId: "db.recentResults",
            tag: "features-tab-history"
        }, {
            tabId: "favourites",
            labelId: "db.favouritesResults",
            tag: "features-tab-favourites"
        }]
        if (Auth.getAnnotationGroup()) {
            this.tabs.push({
                tabId: "annotations",
                labelId: "cc.annotations",
                tag: "features-tab-annotations"
            })
        }

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
            if(!evt.item.item.active){
                evt.preventDefault()
            }
            Dispatcher.trigger("RESET_STORE", evt.item.item.page)
        }

        onBannerToggleClick(evt){
            evt.preventUpdate = true
            this.bannerExpanded = !this.bannerExpanded
            $(this.root).toggleClass("bannerExpanded", this.bannerExpanded)
        }

        this.on("update", this._updateItems)

        this.on("updated", this._updateUrl)

        this.on("mount", () => {
            this._updateUrl()
            AppStore.on("corpusChanged", this.update)
            Auth.getAnnotationGroup() && this.corpus && window.stores.concordance && window.stores.concordance.getAnnotations()
        })

        this.on("unmount", () => {
            AppStore.off("corpusChanged", this.update)
        })

    </script>
</page-dashboard>
