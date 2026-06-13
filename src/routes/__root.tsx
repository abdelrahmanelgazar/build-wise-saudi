import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  useRouter,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { useEffect, type ReactNode } from "react";

import appCss from "../styles.css?url";
import { reportLovableError } from "../lib/lovable-error-reporting";
import { Toaster } from "@/components/ui/sonner";
import { supabase } from "@/integrations/supabase/client";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-primary">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">الصفحة غير موجودة</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          الرابط الذي تحاول الوصول إليه غير صحيح أو تم نقله.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            العودة للرئيسية
          </Link>
        </div>
      </div>
    </div>
  );
}

function ErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  console.error(error);
  const router = useRouter();
  useEffect(() => {
    reportLovableError(error, { boundary: "tanstack_root_error_component" });
  }, [error]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          تعذّر تحميل هذه الصفحة
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          حدث خطأ غير متوقع. يمكنك المحاولة مرة أخرى أو العودة للصفحة الرئيسية.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button
            onClick={() => {
              router.invalidate();
              reset();
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            إعادة المحاولة
          </button>
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent"
          >
            الصفحة الرئيسية
          </a>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "تقديري — منصة تسعير وإدارة المناقصات" },
      {
        name: "description",
        content:
          "منصة احترافية لتقدير تكاليف المقاولات وإدارة المناقصات وتحليل الأسعار للسوق السعودي.",
      },
      { name: "theme-color", content: "#0b1220" },
      { property: "og:title", content: "تقديري — منصة تسعير وإدارة المناقصات" },
      {
        property: "og:description",
        content: "تسعير، تحليل أسعار، وإدارة موارد بالريال السعودي.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:title", content: "تقديري — منصة تسعير وإدارة المناقصات" },
      { name: "description", content: "Saudi Estimator Pro is an enterprise platform for construction cost estimation and tendering." },
      { property: "og:description", content: "Saudi Estimator Pro is an enterprise platform for construction cost estimation and tendering." },
      { name: "twitter:description", content: "Saudi Estimator Pro is an enterprise platform for construction cost estimation and tendering." },
      { property: "og:image", content: "https://pub-bb2e103a32db4e198524a2e9ed8f35b4.r2.dev/05e3c442-5a99-475b-b427-ac48e355325a/id-preview-3ed7533e--4379a275-c031-49e2-8f92-e55e588f95bd.lovable.app-1781339658750.png" },
      { name: "twitter:image", content: "https://pub-bb2e103a32db4e198524a2e9ed8f35b4.r2.dev/05e3c442-5a99-475b-b427-ac48e355325a/id-preview-3ed7533e--4379a275-c031-49e2-8f92-e55e588f95bd.lovable.app-1781339658750.png" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "" },
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap",
      },
    ],
    // GitHub Pages SPA routing: redirect /?/path back to /path
    scripts: [
      {
        dangerouslySetInnerHTML: {
          __html: `(function(){
  var redirect = sessionStorage.redirect;
  delete sessionStorage.redirect;
  if (redirect && redirect !== location.href) {
    history.replaceState(null, null, redirect);
  }
  // Handle /?/ style redirects from 404.html
  var search = location.search;
  if (search.startsWith('?/')) {
    var query = search.slice(2).replace(/~and~/g, '&');
    var hashIndex = query.indexOf('#');
    var hash = hashIndex >= 0 ? query.slice(hashIndex) : '';
    var path = hashIndex >= 0 ? query.slice(0, hashIndex) : query;
    var ampIndex = path.indexOf('&');
    var route = '/' + (ampIndex >= 0 ? path.slice(0, ampIndex) : path);
    var qs = ampIndex >= 0 ? '?' + path.slice(ampIndex + 1) : '';
    history.replaceState(null, null, route + qs + hash);
  }
})();`,
        },
      },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return (
    <html lang="ar" dir="rtl" className="dark">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();
  const router = useRouter();

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((event) => {
      if (event !== "SIGNED_IN" && event !== "SIGNED_OUT" && event !== "USER_UPDATED") return;
      router.invalidate();
      if (event !== "SIGNED_OUT") queryClient.invalidateQueries();
    });
    return () => sub.subscription.unsubscribe();
  }, [router, queryClient]);

  return (
    <QueryClientProvider client={queryClient}>
      <Outlet />
      <Toaster richColors position="top-center" dir="rtl" />
    </QueryClientProvider>
  );
}
