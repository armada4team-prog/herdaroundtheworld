// Stands in for Velo's `wix-data` (the surface wix/backend/handlers.src.js uses: query().eq()
// .hasSome().limit().find(), insert, update, remove), over the Wix Data Items REST API:
//   Query   POST   /wix-data/v2/items/query
//           https://dev.wix.com/docs/api-reference/business-solutions/cms/data-items/query-data-items
//   Insert  POST   /wix-data/v2/items
//           https://dev.wix.com/docs/api-reference/business-solutions/cms/data-items/insert-data-item
//   Update  PUT    /wix-data/v2/items/{id}   (replaces the whole item, like wixData.update)
//           https://dev.wix.com/docs/api-reference/business-solutions/cms/data-items/update-data-item
//   Remove  DELETE /wix-data/v2/items/{id}?dataCollectionId=…
//           https://dev.wix.com/docs/api-reference/business-solutions/cms/data-items/remove-data-item
// Filters are Wix API Query Language: { field: { $eq: v } }, { field: { $hasSome: [..] } }, $and.
import { wixFetch } from '../wix-rest.js';

/** The checker only ever touches the Companion lists (Companions, CompanionStops, …). */
const ALLOWED = /^Companion(s|[A-Z][A-Za-z]*)$/;
function guard(name) {
  if (!ALLOWED.test(String(name))) throw new Error('The checker only uses the Companion lists, not ' + name);
}

const PAGE = 100; // a page size every Wix query method accepts
const DEFAULT_LIMIT = 50; // same as Velo's default when no .limit() is given
const SYSTEM_FIELDS = ['_id', '_createdDate', '_updatedDate'];

/** A Wix REST item → what Velo would give: dates ({ $date }) become ISO strings. */
function fromWix(dataItem) {
  const data = (dataItem && dataItem.data) || {};
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    out[k] = v && typeof v === 'object' && !Array.isArray(v) && typeof v.$date === 'string' ? v.$date : v;
  }
  if (!out._id && dataItem && dataItem.id) out._id = dataItem.id;
  return out;
}

/** What we send: the item without the fields Wix keeps for itself. */
function toWix(item) {
  const data = { ...item };
  for (const k of SYSTEM_FIELDS) delete data[k];
  return data;
}

function query(name) {
  guard(name);
  const filters = [];
  let max = DEFAULT_LIMIT;
  const q = {
    eq(field, value) { filters.push({ [field]: { $eq: value } }); return q; },
    hasSome(field, values) { filters.push({ [field]: { $hasSome: values } }); return q; },
    limit(n) { max = n; return q; },
    async find() {
      const filter = filters.length === 0 ? {} : filters.length === 1 ? filters[0] : { $and: filters };
      const items = [];
      let offset = 0;
      while (items.length < max) {
        const limit = Math.min(PAGE, max - items.length);
        const res = await wixFetch('/wix-data/v2/items/query', {
          body: { dataCollectionId: name, query: { filter, paging: { limit, offset } }, consistentRead: true },
        });
        const page = (res.dataItems || []).map(fromWix);
        items.push(...page);
        if (page.length < limit) break;
        offset += page.length;
      }
      return { items, totalCount: items.length };
    },
  };
  return q;
}

async function insert(name, item) {
  guard(name);
  const res = await wixFetch('/wix-data/v2/items', { body: { dataCollectionId: name, dataItem: { data: toWix(item) } } });
  return fromWix(res.dataItem);
}

async function update(name, item) {
  guard(name);
  if (!item || !item._id) throw new Error('update needs an item with an _id');
  const res = await wixFetch('/wix-data/v2/items/' + encodeURIComponent(item._id), {
    method: 'PUT',
    body: { dataCollectionId: name, dataItem: { id: item._id, data: toWix(item) } },
  });
  return fromWix(res.dataItem);
}

async function remove(name, id) {
  guard(name);
  const res = await wixFetch('/wix-data/v2/items/' + encodeURIComponent(id) + '?dataCollectionId=' + encodeURIComponent(name), { method: 'DELETE' });
  return res.dataItem ? fromWix(res.dataItem) : null;
}

export default { query, insert, update, remove };
