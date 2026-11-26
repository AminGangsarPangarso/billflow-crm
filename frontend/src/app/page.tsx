export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-4 p-8">
      <span className="w-fit rounded-full bg-blue-100 px-3 py-1 text-sm font-medium text-blue-700">Project initialized</span>
      <h1 className="text-4xl font-bold tracking-tight">BillFlow CRM</h1>
      <p className="text-slate-600">Next.js and Tailwind are ready. Next, we will turn your HTML dashboard prototype into reusable components.</p>
      <p className="text-sm text-slate-500">Backend health endpoint: <code>http://localhost:8080/health</code></p>
    </main>
  );
}
