const showMoreText = 
        '{{#isShowingMore}}' +
        i18n.show_less +
        '{{/isShowingMore}}' +
        '{{^isShowingMore}}' +
        i18n.show_more +
        '{{/isShowingMore}}';

const css_showmore = 'btn btn-outline-primary';

const router = instantsearch.routers.history({
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
    return {
      query: uiState.pubs_test.query,
      page: uiState.pubs_test.page,
      type:
        uiState.pubs_test.refinementList &&
        uiState.pubs_test.refinementList.type,
      year:
        uiState.pubs_test.refinementList &&
        uiState.pubs_test.refinementList.year,
      author:
        uiState.pubs_test.refinementList &&
        uiState.pubs_test.refinementList.author,
      project:
        uiState.pubs_test.refinementList &&
        uiState.pubs_test.refinementList.project,
    };
  },

  routeToState(routeState) {
    // refer to uiState docs for details: https://www.algolia.com/doc/api-reference/widgets/ui-state/js/
    return {
      // eslint-disable-next-line camelcase
      pubs_test: {
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
  indexName: 'pubs_test',
  searchClient: algoliasearch('FUZHRLXPF4', '7fb333226a19b1a7af131612dd428928'),
  routing: searchRouting,
  /* https://discourse.algolia.com/t/limit-searches-to-3-characters-or-more-with-instantsearch/8067/2 */
});

search.addWidgets([
  instantsearch.widgets.analytics({
    pushFunction(formattedParameters, state, results) {
      /*  help needed: add code for Matomo  (https://developer.matomo.org/guides/tracking-javascript-guide)*/
    },
  }),
  instantsearch.widgets.currentRefinements({
    container: '#current-refinements',
  }),
  instantsearch.widgets.searchBox({
    container: '#searchbox',
    placeholder: i18n.placeholder,
  }),
  instantsearch.widgets.stats({
  container: '#stats',
  templates: {
      text: `
      {{#hasNoResults}}Keine Ergebnisse{{/hasNoResults}}
      {{#hasOneResult}}1 Ergebnis{{/hasOneResult}}
      {{#hasManyResults}}{{#helpers.formatNumber}}{{nbHits}}{{/helpers.formatNumber}} Ergebnisse{{/hasManyResults}}
      gefunden in {{processingTimeMS}}ms
    `,
	},
  }),
  instantsearch.widgets.clearRefinements({
    container: '#clear-refinements',
    templates: {
    resetLabel: 'Filter zurücksetzen',
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
      { label: '5 ' + i18n.hits_per_page, value: 5, default: true },
      { label: '10 ' + i18n.hits_per_page, value: 10 },
      { label: '20 ' + i18n.hits_per_page, value: 20 },
    ],
  }),
  instantsearch.widgets.hits({
    container: '#hits',
    templates: {
      empty: `<div>
      <p>Keine Suchergebnisse für: {{ query }}</p>
      <a role="button" href="/de/publication/">Filter zurücksetzen</a>
      </div>`,
      item: function (data) {
        const base_url = '';
        const abstract_id = 'abstract-' + data.__hitIndex + 1;
        const authors = data._highlightResult.author
          .map((a) => '<a href="?author=' + a.value + '">' + a.value + '</a>')
          .join(', ');
        let project = '';
        if (data.project !== null) {
          project += data._highlightResult.project
            .map(
              (p) =>
                '<a class="btn btn-outline-primary my-1 mr-1 btn-sm" href="?project=' +
                p.value +
                '">' +
                data.project_btn +
                ': ' +
                p.value +
                '</a>'
            )
            .join('');
        }
        const cite =
          '<button class="btn btn-outline-primary my-1 mr-1 btn-sm js-cite-modal" type="button" data-filename="' +
          base_url +
          data.cite_link +
          '">' +
          i18n.btn_cite +
          '</button>';
        let pdf = '';
        if (data.pdf !== '') {
          pdf +=
            '<a class="btn btn-outline-primary my-1 mr-1 btn-sm" href="' +
            base_url +
            data.pdf +
            '" target="_blank" rel="noopener">' +
			i18n.btn_pdf + 
			'</a>';
        }
        let doi = '';
        if (data.doi !== null) {
          doi +=
            '<a class="btn btn-outline-primary my-1 mr-1 btn-sm" href="' +
            base_url +
            data.doi +
            '">DOI</a>';
        }
		let abstract = '';
		if (data.summary !== '') {
		  abstract += 
		  '<button type="button" class="btn btn-info" data-toggle="collapse" data-target="#' +
            abstract_id +
            '">' + 
            i18n.abstract +
            '</button>'
		}
        const links = '<p>' + cite + doi + pdf + project + '</p>';
        const publication =
          '<div class="pub-list-item" style="margin-bottom: 1rem">' +
          '<i class="far fa-file-alt pub-icon" aria-hidden="true"></i>' +
          '<span class="article-metadata li-cite-author">' +
          authors +
          '</span>' +
          ' (' +
          data._highlightResult.year.value +
          '): <a href= ' +
          data.relpermalink +
          '> ' +
          data._highlightResult.title.value +
          '</a>. ' +
          data.publication +
          links +
          '</div>';
        if (data.summary === '') {
          return publication;
        } else {
          return (
            publication +
			abstract +
            '<div id="' +
            abstract_id +
            '" class="collapse show multi-collapse">' +
            data._highlightResult.summary.value +
            '</div>'
          );
        }
      },
    },
  }),

  instantsearch.widgets.pagination({
    container: '#pagination',
  }),
]);

search.start();
