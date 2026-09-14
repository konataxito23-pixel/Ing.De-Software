import { useNavigate } from "react-router-dom"

function Login() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center px-6">
      <div className="w-full max-w-md">

        {/* Logo */}
        <div className="text-center mb-10">
          <h1 className="text-4xl font-bold tracking-tight text-white">
            NEXORA
          </h1>

          <p className="mt-2 text-slate-400">
            Banca móvil inteligente
          </p>
        </div>

        {/* Login Card */}
        <div className="rounded-2xl bg-white p-8 shadow-2xl">

          <h2 className="text-2xl font-bold text-slate-900">
            Bienvenido
          </h2>

          <p className="mt-2 text-sm text-slate-500">
            Ingresa a tu cuenta para continuar
          </p>

          {/* Usuario */}
          <div className="mt-8">
            <label className="block text-sm font-medium text-slate-700">
              Usuario
            </label>

            <input
              type="text"
              placeholder="Ingresa tu usuario"
              className="mt-2 w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />
          </div>

          {/* Contraseña */}
          <div className="mt-5">
            <label className="block text-sm font-medium text-slate-700">
              Contraseña
            </label>

            <input
              type="password"
              placeholder="Ingresa tu contraseña"
              className="mt-2 w-full rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />
          </div>

          {/* Iniciar sesión */}
          <button
            onClick={() => navigate("/dashboard")}
            className="mt-7 w-full rounded-xl bg-blue-600 py-3.5 font-semibold text-white transition hover:bg-blue-700"
          >
            Iniciar sesión
          </button>

          <p className="mt-6 text-center text-xs text-slate-400">
            Entorno de simulación académica
          </p>

        </div>
      </div>
    </div>
  )
}

export default Login