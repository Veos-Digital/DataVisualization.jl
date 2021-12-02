struct Tabular{T}
    data::Observable{T}
end

render_row_value(x::AbstractFloat) = round(x, sigdigits=6)
render_row_value(x::Integer) = x
render_row_value(x::Missing) = "n/a"
render_row_value(x::String) = x
render_row_value(x) = string(x)

function jsrender(session::Session, tabular::Tabular)
    metadata = map(session, tabular.data) do data
        cols = Tables.columns(data)
        names = collect(Tables.columnnames(cols))
        columns = [map(render_row_value, Tables.getcolumn(cols, name)) for name in names]
        (; names, columns)
    end
    JSServe.register_resource!(session, metadata)

    table_div = DOM.div()
    create_table = js"""
        function create_table(div, m) {
            const names = m.names;
            const columns = m.columns;
            const indices = Object.keys(columns[0])

            const columnDefs = names.map(name => {
                return {field: name, headerName: name};
            });
            const rowData = indices.map(i => {
                const row = {}
                for (let colIdx in columns) {
                    row[names[colIdx]] = columns[colIdx][i];
                }
                return row
            });

            const rem2pix = parseFloat(getComputedStyle(document.documentElement).fontSize);
            const rowHeight = 2.5 * rem2pix;
            const headerHeight = 3.75 * rem2pix;

            // let the grid know which columns and what data to use
            const gridOptions = {
                defaultColDef: {
                    sortable: true,
                    resizable: true,
                    headerClass: "text-blue-800 text-xl font-semibold px-4 hover:bg-gray-200",
                    cellClass: "px-4 text-base",
                },
                columnDefs: columnDefs,
                rowData: rowData,
                headerHeight: headerHeight,
                getRowHeight: params => {
                    return rowHeight;
                },
                getRowClass: params => {
                    return "hover:bg-gray-200";
                },
                suppressFieldDotNotation: true,
            };

            new $(agGrid).Grid(div, gridOptions);
        }
    """
    onload(session, table_div, js"div => ($create_table)(div, JSServe.get_observable($metadata))")
    onjs(session, metadata, js"""
        function (m) {
            const table_div = $(table_div);
            while (table_div.firstChild) {
                table_div.removeChild(table_div.lastChild);
            }
            ($create_table)(table_div, m);
        }
    """)
    return table_div
end
