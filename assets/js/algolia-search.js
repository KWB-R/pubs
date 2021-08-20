// Show/Hide Abstract

let abstractCollapsed = sessionStorage.getItem('abstractCollapsed') === 'true' || false
const collapseAll = function() {
  setTimeout(function() {
    if (abstractCollapsed === true) {
      $('.multi-collapse').collapse()
    }
    setButtonText(abstractCollapsed)
  },200)
}
const setButtonText = function(hide) {
  const btn = $('#abstracts-toggle')
  if (hide) {
    btn.html(btn.data('hide'))
  } else {
    btn.html(btn.data('show'))
  }
}
$(document).ready(collapseAll)

$('#abstracts-toggle').click(function() {
  abstractCollapsed = !abstractCollapsed
  setButtonText(abstractCollapsed)
  sessionStorage.setItem('abstractCollapsed',abstractCollapsed)
})

// Aside Toggle

$('body').css('--height', window.innerHeight + "px")

let htmlBody = $('body');
let scrollPos = 0;
const disableScroll = function() {
  scrollPos = document.documentElement.scrollTop
  htmlBody.css('top', -scrollPos + 'px').addClass('disable-scroll')
}

const enableScroll = function() {
  htmlBody.removeClass('disable-scroll')
  $(window).scrollTop(this.scrollPos)
}

$('.aside-collapse').on('show.bs.collapse', function () {
  console.log("show", this)
  // $(this).css('top',scrollPos)
  disableScroll()
})
$('.aside-collapse').on('hide.bs.collapse', function () {
  console.log("hide")
  // $(this).css('top',scrollPos)
  enableScroll()
})

// Algolia

const showMoreText = 
        '{{#isShowingMore}}' +
        i18n.show_less +
        '{{/isShowingMore}}' +
        '{{^isShowingMore}}' +
        i18n.show_more +
        '{{/isShowingMore}}';


const css_showmore = 'btn btn-underline';

const router = instantsearch.routers.history({
  windowTitle() {
    collapseAll()
  }, 
  createURL({ qsModule, routeState, location }) {
    /*const urlParts = location.href.match(/^(.*?)\/search/);*/
    /*const urlParts = location.href.match(/^(.*\/de\/publication\/)/search/);*/
    /*const baseUrl = `${urlParts ? urlParts[1] : ''}/`;*/
    const baseUrl = url_publication;
    const queryParameters = {};

    if (routeState.query) {
      queryParameters.query = encodeURIComponent(routeState.query);
    }
    if (routeState.page !== 1) {
      queryParameters.page = routeState.page;
    }
    if (routeState.type) {
      queryParameters.type = routeState.type.map(encodeURIComponent);
    }
    if (routeState.year) {
      queryParameters.year = routeState.year.map(encodeURIComponent);
    }
    if (routeState.author) {
      queryParameters.author = routeState.author.map(encodeURIComponent);
    }
    if (routeState.project) {
      queryParameters.project = routeState.project.map(encodeURIComponent);
    }

    const queryString = qsModule.stringify(queryParameters, {
      addQueryPrefix: true,
      arrayFormat: 'repeat',
    });

    return `${baseUrl}${queryString}`;
  },

  parseURL({ qsModule, location }) {
    const {
      query = '',
      page,
      type = [],
      year = [],
      author = [],
      project = [],
    } = qsModule.parse(location.search.slice(1));
    // `qs` does not return an array when there's a single value.
    const allTypes = Array.isArray(type) ? type : [type].filter(Boolean);
    const allYears = Array.isArray(year) ? year : [year].filter(Boolean);
    const allAuthors = Array.isArray(author)
      ? author
      : [author].filter(Boolean);
    const allProjects = Array.isArray(project)
      ? project
      : [project].filter(Boolean);

    return {
      query: decodeURIComponent(query),
      page,
      type: allTypes.map(decodeURIComponent),
      year: allYears.map(decodeURIComponent),
      author: allAuthors.map(decodeURIComponent),
      project: allProjects.map(decodeURIComponent),
    };
  },
});

const stateMapping = {
  stateToRoute(uiState) {
    // refer to uiState docs for details: https://www.algolia.com/doc/api-reference/widgets/ui-state/js/
    const indexUiState = uiState[algolia.index_name] || {};
	  
	return {
      query: indexUiState.query,
      page: indexUiState.page,
      type:
        indexUiState.refinementList &&
        indexUiState.refinementList.type,
      year:
        indexUiState.refinementList &&
        indexUiState.refinementList.year,
      author:
        indexUiState.refinementList &&
        indexUiState.refinementList.author,
      project:
        indexUiState.refinementList &&
        indexUiState.refinementList.project,
    };
  },

  routeToState(routeState) {
    // refer to uiState docs for details: https://www.algolia.com/doc/api-reference/widgets/ui-state/js/
    return {
      // eslint-disable-next-line camelcase
      [algolia.index_name]: {
        query: routeState.query,
        page: routeState.page,
        refinementList: {
          type: routeState.type,
          year: routeState.year,
          author: routeState.author,
          project: routeState.project,
        },
      },
    };
  },
};

const searchRouting = {
  router,
  stateMapping,
};


/* global instantsearch algoliasearch */

const search = instantsearch({
  indexName: algolia.index_name,
  searchClient: algoliasearch(algolia.app_id, algolia.api_key),
  routing: searchRouting,
  /* https://discourse.algolia.com/t/limit-searches-to-3-characters-or-more-with-instantsearch/8067/2 */
});

search.addWidgets([
  instantsearch.widgets.analytics({
    pushFunction(formattedParameters, state, results) {
      window._paq.push([
        'setCustomUrl',
        url_publication + window.location.search,
      ]);
      window._paq.push(['trackPageView']);
    },
    delay: 5000,
    triggerOnUIInteraction: true,
    pushPagination: true,
  }),
  instantsearch.widgets.poweredBy({
    container: '#powered-by',
  }),
  instantsearch.widgets.currentRefinements({
    container: '#current-refinements',
  }),
  instantsearch.widgets.searchBox({
    container: '#searchbox',
    placeholder: i18n.placeholder,
  }),
  // instantsearch.widgets.stats({
  // container: '#stats',
  // templates: {
  //     text: '{{#hasNoResults}}' + i18n.no_results + '{{/hasNoResults}}' +
  //     '{{#hasOneResult}}' + i18n.one_result + '{{/hasOneResult}}' +
  //     '{{#hasManyResults}}{{#helpers.formatNumber}}{{nbHits}}{{/helpers.formatNumber}}' + ' ' + i18n.results + 
  //     '{{/hasManyResults}}' + ' ' + i18n.found_in + ' ' + '{{processingTimeMS}}ms. ',
  //   },
  // }),
  instantsearch.widgets.clearRefinements({
    container: '#clear-refinements',
    templates: {
    resetLabel: i18n.reset_filters,
  },
  }),
  instantsearch.widgets.refinementList({
    container: '#pubs-list',
    attribute: 'type',
    sortBy: ['name:asc'],
  }),
  instantsearch.widgets.refinementList({
    container: '#year-list',
    attribute: 'year',
    sortBy: ['name:desc'],
    showMore: true,
    limit: 5,
    templates: {
    showMoreText: showMoreText,
    },
	cssClasses: {
        showMore: css_showmore
      },
  }),
  instantsearch.widgets.refinementList({
    container: '#author-list',
    attribute: 'author',
    operator: 'and',
    sortBy: ['count:desc'],
    showMore: true,
    limit: 5,
    searchable: true,
    searchablePlaceholder: i18n.placeholder,
    templates: {
    showMoreText: showMoreText,
    },
	cssClasses: {
        showMore: css_showmore
      },
  }),
  instantsearch.widgets.refinementList({
    container: '#project-list',
    attribute: 'project',
    sortBy: ['count:desc'],
    showMore: true,
    limit: 5,
    searchable: true,
    searchablePlaceholder: i18n.placeholder,
    templates: {
    showMoreText: showMoreText,
    },
    cssClasses: {
     showMore: css_showmore
    },
  }),
  instantsearch.widgets.hitsPerPage({
    container: '#hits-per-page',
    items: [
      { label: '   5 ' + i18n.hits_per_page, value: 5},
      { label: '  10 ' + i18n.hits_per_page, value: 10, default: true  },
      { label: '  25 ' + i18n.hits_per_page, value: 25 },
      { label: '  50 ' + i18n.hits_per_page, value: 50 },
      { label: ' 100 ' + i18n.hits_per_page, value: 100 },
      { label: ' 250 ' + i18n.hits_per_page, value: 250 },
      { label: ' 500 ' + i18n.hits_per_page, value: 500 },
      { label: '1000 ' + i18n.hits_per_page, value: 1000 },

    ],
  }),
  instantsearch.widgets.hits({
    container: '#hits',
    templates: {
      empty: '<div><p>' + i18n.no_results + ' ' + i18n.for + ': "' +  '{{query}}' + '" </p><a role="button" href="' + url_publication + '">' + i18n.reset_filters + '</a></div>',
      item: function (data) {
        const base_url = '';
        const abstract_id = 'abstract-' + data.__hitIndex + 1;
        const authors_link = data.author.map(
          (a) => '<a class="piwik_link" href="?author=' + a + '">'
        );
        const authors_name = data._highlightResult.author.map(
          (a) => a.value + '</a>'
        );
        const authors = authors_link.map(function (x, i) {
          return [x, authors_name[i]].join(' ');
        });
        let project = '';

        if (data.project !== null) {
          const project_link = data.project.map(
            (p) =>
              '<a class="btn btn-primary my-1 mr-1 fnt-xs piwik_link" href="?project=' +
              p +
              '">' +
              data.project_btn +
              ': '
          );

          const project_name = data._highlightResult.project.map(
            (p) => p.value + '</a>'
          );
          project += project_link
            .map(function (x, i) {
              return [x, project_name[i]].join('');
            })
            .join(' ');
        }
        const cite =
          '<a class="btn btn-primary my-1 mr-1 fnt-xs matomo_download piwik-link js-cite-modal" data-filename="'+
          base_url +
          data.cite_link +
          '" href="' +
          base_url +
          data.cite_link +
          '">' +
          i18n.btn_cite +
          '</a>';
        let pdf = '';
        if (data.pdf !== '') {
          pdf +=
            '<a class="btn btn-primary my-1 mr-1 fnt-xs matomo_download" href="' +
            base_url +
            data.pdf +
            '" target="_blank" rel="noopener">' +
			i18n.btn_pdf + 
			'</a>';
        }
        let doi = '';
        if (data.doi !== null) {
          doi +=
            '<a class="btn btn-primary my-1 mr-1 fnt-xs piwik_link" href="' +
            'https://doi.org/' +
            data.doi +
            '" target="_blank" rel="noopener">DOI</a>';
        }
		let abstract = '';
		if (data.summary !== '') {
		  abstract += 
		  '<button type="button" class="btn btn-abstract btn-underline fnt-xs d-none d-sm-block" data-toggle="collapse" data-target="#' +
            abstract_id +
            '">' + 
            i18n.abstract +
            '</button>'
		}
        const links = '<div class="pub-item-links">' + cite + doi + pdf + project + '</div>';
        const publication =
          '<div class="pub-list-item fnt-m">' +
          // '<i class="far fa-file-alt pub-icon" aria-hidden="true"></i>' +
          '<span class="article-metadata li-cite-author">' +
          authors +
          '</span>' +
          ' (' +
          data._highlightResult.year.value +
          '): <a class="pub-title" href= ' +
          data.relpermalink +
          '> ' +
          data._highlightResult.title.value +
          '</a>. ' +
          data.publication +
          '</div>' + 
          links;
        if (data.summary === '') {
          return publication;
        } else {
          return (
            publication +
			abstract +
            '<div id="' +
            abstract_id +
            '" class="collapse show multi-collapse d-none d-sm-block fnt-xs pub-item-abstract ">' +
            data._highlightResult.summary.value +
            '</div>'
          );
        }
      },
    },
  }),

  instantsearch.widgets.pagination({
    container: '#pagination',
    padding: 2
  }),
]);

search.start();
