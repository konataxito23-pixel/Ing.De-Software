function Dashboard() {
  return (
    <div className="min-h-screen bg-slate-100">

      {/* Navbar */}
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">

          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            NEXORA
          </h1>

          <div className="flex items-center gap-4">
            <button className="text-slate-500 hover:text-slate-900">
              🔔
            </button>

            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-600 font-semibold text-white">
              J
            </div>
          </div>

        </div>
      </header>

      {/* Contenido */}
      <main className="mx-auto max-w-6xl px-6 py-8">

        {/* Saludo */}
        <div>
          <p className="text-sm text-slate-500">
            Bienvenido de nuevo
          </p>

          <h2 className="mt-1 text-3xl font-bold text-slate-900">
            Hola, Julián 👋
          </h2>
        </div>

        {/* Saldo */}
        <div className="mt-8 rounded-2xl bg-slate-950 p-8 text-white shadow-lg">

          <p className="text-sm text-slate-400">
            Saldo disponible
          </p>

          <p className="mt-3 text-4xl font-bold">
            $4.850.000
          </p>

          <p className="mt-2 text-sm text-slate-400">
            COP
          </p>

        </div>

        {/* Acciones */}
        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">

          <button className="rounded-2xl bg-blue-600 p-5 text-left text-white shadow-sm transition hover:bg-blue-700">

            <p className="text-lg font-semibold">
              Transferir
            </p>

            <p className="mt-1 text-sm text-blue-100">
              Envía dinero a una cuenta
            </p>

          </button>

          <button className="rounded-2xl bg-white p-5 text-left text-slate-900 shadow-sm transition hover:bg-slate-50">

            <p className="text-lg font-semibold">
              Historial
            </p>

            <p className="mt-1 text-sm text-slate-500">
              Consulta tus movimientos
            </p>

          </button>

        </div>

        {/* Cuenta */}
        <section className="mt-8">

          <h3 className="text-xl font-bold text-slate-900">
            Mis cuentas
          </h3>

          <div className="mt-4 rounded-2xl bg-white p-6 shadow-sm">

            <div className="flex items-center justify-between">

              <div>
                <p className="font-semibold text-slate-900">
                  Cuenta de ahorros
                </p>

                <p className="mt-1 text-sm text-slate-500">
                  •••• 4821
                </p>
              </div>

              <p className="font-bold text-slate-900">
                $4.850.000
              </p>

            </div>

          </div>

        </section>

        {/* Movimientos */}
        <section className="mt-8">

          <div className="flex items-center justify-between">

            <h3 className="text-xl font-bold text-slate-900">
              Últimos movimientos
            </h3>

            <button className="text-sm font-semibold text-blue-600 hover:text-blue-700">
              Ver todos
            </button>

          </div>

          <div className="mt-4 overflow-hidden rounded-2xl bg-white shadow-sm">

            <div className="flex items-center justify-between border-b border-slate-100 p-5">

              <div>
                <p className="font-semibold text-slate-900">
                  Transferencia recibida
                </p>

                <p className="mt-1 text-sm text-slate-500">
                  Hoy, 10:32 AM
                </p>
              </div>

              <p className="font-semibold text-green-600">
                +$500.000
              </p>

            </div>

            <div className="flex items-center justify-between p-5">

              <div>
                <p className="font-semibold text-slate-900">
                  Transferencia enviada
                </p>

                <p className="mt-1 text-sm text-slate-500">
                  Ayer, 4:15 PM
                </p>
              </div>

              <p className="font-semibold text-red-500">
                -$120.000
              </p>

            </div>

          </div>

        </section>

      </main>

    </div>
  )
}

export default Dashboard